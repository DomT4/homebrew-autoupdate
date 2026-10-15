# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "open3"
require "shellwords"
require "tmpdir"

class CommandTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__).freeze
  BREW = ENV.fetch("HOMEBREW_BREW_FILE") do
    ENV.fetch("PATH").split(File::PATH_SEPARATOR).filter_map do |directory|
      path = File.expand_path("brew", directory)
      path if File.file?(path) && File.executable?(path)
    end.first || raise("Homebrew executable not found in PATH")
  end.freeze
  ENVIRONMENT = {
    "HOMEBREW_NO_ANALYTICS"        => "1",
    "HOMEBREW_NO_AUTO_UPDATE"      => "1",
    "HOMEBREW_NO_INSTALL_FROM_API" => "1",
    "HOMEBREW_NO_COLOR"            => "1",
    "LC_ALL"                       => "C",
  }.freeze
  VERSION = File.read(File.join(ROOT, "VERSION")).strip.freeze

  GENERATE_UPDATER = <<~'RUBY'
    require "abstract_command"
    require "json"
    root, temporary_directory, environment = ARGV.shift(3)
    require File.join(root, "cmd/autoupdate")
    require File.join(root, "lib/autoupdate")
    directory = Pathname.new(temporary_directory)
    JSON.parse(environment).each { |name, value| value.nil? ? ENV.delete(name) : ENV[name] = value }
    Autoupdate::Core.define_singleton_method(:location) { directory/"config" }
    Autoupdate::Core.define_singleton_method(:logs) { (directory/"logs").to_s }
    Autoupdate::Core.define_singleton_method(:fallback_logs) { directory.to_s }
    Autoupdate::Core.define_singleton_method(:plist) { (directory/"agent.plist").to_s }
    Autoupdate::Core.define_singleton_method(:brew) { directory/"fake-brew" }
    Autoupdate::Notify.define_singleton_method(:command) { |mode:| ":" }
    Utils.define_singleton_method(:popen_read) { |*| "" }
    SystemCommand.define_singleton_method(:quiet_system) do |*arguments|
      raise "Unexpected command: #{arguments.inspect}" unless arguments == ["/bin/launchctl", "load", Autoupdate::Core.plist]

      true
    end
    Homebrew::Cmd::Autoupdate.new(ARGV).run
    puts Autoupdate.configuration_summary
  RUBY

  def test_root_help_lists_subcommands
    stdout, stderr, status = brew_autoupdate("--help")

    assert_predicate status, :success?, stderr
    assert_includes stdout, "Subcommands:"
    assert_includes stdout, "start:"
    assert_includes stdout, "status:"
    assert_includes stdout, "logs:"
    assert_includes stdout, "brew autoupdate start 12h --upgrade --cleanup --immediate"
    assert_includes stdout, "--only=wget,node,firefox"
    assert_includes stdout, "brew autoupdate logs --follow"
    assert_includes stdout, "brew autoupdate start --help"
  end

  def test_start_help_lists_only_start_options
    stdout, stderr, status = brew_autoupdate("start", "--help")

    assert_predicate status, :success?, stderr
    assert_includes stdout, "Usage: brew autoupdate start"
    assert_includes stdout, "--upgrade"
    assert_includes stdout, "--cleanup"
    assert_includes stdout, "--notify-on-error"
    assert_includes stdout, "--no-notify"
    refute_includes stdout, "--follow"
    refute_includes stdout, "--lines"
  end

  def test_start_help_documents_the_clock_time_schedule
    stdout, stderr, status = brew_autoupdate("start", "--help")

    assert_predicate status, :success?, stderr
    assert_includes stdout, "00:00"
  end

  def test_logs_help_lists_only_log_options
    stdout, stderr, status = brew_autoupdate("logs", "--help")

    assert_predicate status, :success?, stderr
    assert_includes stdout, "Usage: brew autoupdate logs"
    assert_includes stdout, "--follow"
    assert_includes stdout, "--lines"
    refute_includes stdout, "--upgrade"
  end

  def test_options_are_rejected_for_the_wrong_subcommand
    output, status = brew_autoupdate_error("status", "--upgrade")

    refute_predicate status, :success?
    assert_includes output, "The `status` subcommand does not accept the `--upgrade` switch."
  end

  def test_upgrade_options_enforce_dependencies_and_conflicts
    output, status = brew_autoupdate_error("start", "--greedy")
    refute_predicate status, :success?
    assert_includes output, "`--greedy` cannot be passed without `--upgrade`."

    output, status = brew_autoupdate_error("start", "--only=wget")
    refute_predicate status, :success?
    assert_includes output, "`--only` cannot be passed without `--upgrade`."

    output, status = brew_autoupdate_error("start", "--upgrade", "--only=wget", "--leaves-only")
    refute_predicate status, :success?
    assert_includes output, "Options --only and --leaves-only are mutually exclusive."
  end

  def test_notification_modes_are_mutually_exclusive
    output, status = brew_autoupdate_error("start", "--notify-on-error", "--no-notify")

    refute_predicate status, :success?
    assert_includes output, "Options --notify-on-error and --no-notify are mutually exclusive."
  end

  def test_invalid_intervals_are_rejected_before_starting
    output, status = brew_autoupdate_error("start", "tomorrow")

    refute_predicate status, :success?
    assert_includes output, "The interval must be positive seconds"
  end

  def test_invalid_clock_times_are_rejected_before_starting
    output, status = brew_autoupdate_error("start", "24:00")

    refute_predicate status, :success?
    assert_includes output, "The interval must be positive seconds"
  end

  def test_log_line_count_must_be_positive
    output, status = brew_autoupdate_error("logs", "--lines=0")

    refute_predicate status, :success?
    assert_includes output, "`--lines` must be a positive integer."
  end

  def test_legacy_subcommand_switches_remain_supported
    stdout, stderr, status = brew_autoupdate("--status")

    assert_predicate status, :success?, stderr
    assert_match(/Autoupdate is (?:installed|not configured)/, stdout)
  end

  def test_version_uses_the_shared_version_file
    stdout, stderr, status = brew_autoupdate("version")

    assert_predicate status, :success?, stderr
    assert_match(/\AVersion #{Regexp.escape(VERSION)}\n/o, stdout)
    refute_includes stdout, "Last Changed"
  end

  def test_generated_upgrade_commands_disable_confirmation
    source = File.read(File.join(ROOT, "lib/autoupdate/start.rb"))
    upgrade_lines = source.lines.grep(/Autoupdate::Core\.brew\} upgrade /)

    assert_equal 4, upgrade_lines.length
    upgrade_lines.each do |line|
      assert_includes line, "upgrade --no-ask"
    end
  end

  def test_sudo_askpass_extracts_and_decodes_pinentry_data
    source = File.read(File.join(ROOT, "lib/autoupdate/start.rb"))
    awk_program = source.match(%r{/usr/bin/awk '([^']+)'})&.captures&.first

    refute_nil awk_program

    pinentry_output = "D p%25ss\nD  leading space\nD \tleading tab\nD D\nOK\n"
    stdout, stderr, status = Open3.capture3("/usr/bin/awk", awk_program, stdin_data: pinentry_output)

    assert_predicate status, :success?, stderr
    assert_equal "p%ss\n leading space\n\tleading tab\nD\n", stdout
  end

  def test_sudo_askpass_is_refreshed_when_its_contents_change
    source = File.read(File.join(ROOT, "lib/autoupdate/start.rb"))

    assert_includes source, "!sudo_gui_script.exist? || sudo_gui_script.read != sudo_gui_script_contents"
    assert_includes source, "sudo_gui_script.atomic_write(sudo_gui_script_contents)"
  end

  def test_generated_updater_preserves_homebrew_preferences
    environment = {
      "HOMEBREW_AUTO_UPDATE_SECS"              => "86400",
      "HOMEBREW_NO_UPDATE_REPORT_NEW"          => "1",
      "HOMEBREW_NO_ANALYTICS"                  => "1",
      "HOMEBREW_CLEANUP_MAX_AGE_DAYS"          => "30",
      "HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS" => "1",
      "HOMEBREW_API_AUTO_UPDATE_SECS"          => "900",
      "HOMEBREW_AUTO_UPDATE_QUIET"             => "1",
      "HOMEBREW_NO_AUTOREMOVE"                 => "1",
      "HOMEBREW_NO_INSTALL_CLEANUP"            => "1",
      "HOMEBREW_NO_CLEANUP_FORMULAE"           => "node,python",
      "HOMEBREW_CLEANUP_PERIODIC_FULL_DAYS"    => "7",
      "HOMEBREW_NO_UPGRADE_QUIT_CASKS"         => "1",
      "HOMEBREW_UPGRADE_GREEDY_CASKS"          => "iterm2,obsidian",
      "HOMEBREW_CASK_OPTS"                     => "--appdir=/Applications",
      "HOMEBREW_DOWNLOAD_CONCURRENCY"          => "2",
      "HOMEBREW_CURL_RETRIES"                  => "5",
      "HOMEBREW_NO_INSECURE_REDIRECT"          => "1",
      "HOMEBREW_VERIFY_ATTESTATIONS"           => "1",
      "HOMEBREW_NO_SUDO"                       => "1",
      "HOMEBREW_LOCK_CONTEXT"                  => "scheduled updater",
      "http_proxy"                             => "http://127.0.0.1:8080",
      "https_proxy"                            => "http://127.0.0.1:8080",
      "all_proxy"                              => "socks5://127.0.0.1:1080",
      "ftp_proxy"                              => "http://127.0.0.1:8080",
      "no_proxy"                               => "localhost,127.0.0.1",
    }
    with_updater(environment:) do |directory, _|
      (directory/"fake-brew").write "#!/bin/sh\n/usr/bin/env\n"
      # A LaunchAgent starts without the preferences exported by the user's shell.
      absent_environment = environment.transform_values { nil }
      stdout, stderr, status = Open3.capture3(absent_environment, (directory/"config/brew_autoupdate").to_s)
      assert_predicate status, :success?, stderr
      actual = stdout.lines(chomp: true).filter_map do |line|
        name, value = line.split("=", 2)
        [name, value] if environment.key?(name)
      end.to_h
      assert_equal environment, actual
    end
  end

  def test_captured_homebrew_preferences_are_shell_escaped
    environment = { "HOMEBREW_NO_UPDATE_REPORT_NEW" => "1 $(printf injected); value with spaces" }
    with_updater(environment:) do |directory, _|
      (directory/"fake-brew").write <<~SH
        #!/bin/sh
        printf '%s\\n' "$HOMEBREW_NO_UPDATE_REPORT_NEW"
      SH
      stdout, stderr, status = Open3.capture3((directory/"config/brew_autoupdate").to_s)
      assert_predicate status, :success?, stderr
      assert_equal [environment.fetch("HOMEBREW_NO_UPDATE_REPORT_NEW")], stdout.lines(chomp: true).drop(1)
    end
  end

  def test_credentials_and_homebrew_process_state_are_not_saved
    environment = {
      "HOMEBREW_GITHUB_API_TOKEN"                 => "test-only-not-a-real-token",
      "HOMEBREW_GITHUB_PACKAGES_TOKEN"            => "test-only-not-a-real-token",
      "HOMEBREW_DOCKER_REGISTRY_BASIC_AUTH_TOKEN" => "test-only-not-a-real-token",
      "HOMEBREW_DOCKER_REGISTRY_TOKEN"            => "test-only-not-a-real-token",
      "HOMEBREW_BUNDLE_SECRETS"                   => "test-only-secret-reference",
      "HOMEBREW_COMMAND_DEPTH"                    => "99",
      "HOMEBREW_USER_SET_VARS"                    => "test-only-process-state",
      "HOMEBREW_SYSTEM_ENV_TAKES_PRIORITY"        => "1",
      "HOMEBREW_SUDO_THROUGH_SUDO_USER"           => "1",
      "HOMEBREW_UNKNOWN_CUSTOM_SETTING"           => "test-only-unknown-setting",
      "HOMEBREW_API_DOMAIN"                       => "https://user:test-only-password@example.invalid/api",
      "http_proxy"                                => "http://user:test-only-password@127.0.0.1:8080",
    }
    with_updater(environment:) do |directory, _|
      script = (directory/"config/brew_autoupdate").read
      environment.each_key { |name| refute_match(/^export #{name}=/, script) }
      refute_includes script, "test-only-not-a-real-token"
      refute_includes script, "test-only-password"
    end
  end

  def test_unset_preferences_are_not_replaced_with_homebrew_defaults
    environment = {
      "HOMEBREW_CURL_RETRIES"              => nil,
      "HOMEBREW_DOWNLOAD_CONCURRENCY"      => nil,
      "HOMEBREW_NO_UPGRADE_QUIT_CASKS"     => nil,
      "HOMEBREW_NO_BOTTLE_SOURCE_FALLBACK" => "0",
    }
    with_updater(environment:) do |directory, _|
      script = (directory/"config/brew_autoupdate").read
      environment.keys.first(3).each { |name| refute_match(/^export #{name}=/, script) }
      assert_includes script, "export HOMEBREW_NO_BOTTLE_SOURCE_FALLBACK=1"
      refute_includes script, "export HOMEBREW_NO_BOTTLE_SOURCE_FALLBACK=0"
    end
  end

  def test_custom_homebrew_config_directory_is_preserved
    Dir.mktmpdir("autoupdate-xdg") do |config_home|
      %w[XDG_CONFIG_HOME HOMEBREW_XDG_CONFIG_HOME].each do |config_variable|
        environment = { "XDG_CONFIG_HOME" => nil, "HOMEBREW_XDG_CONFIG_HOME" => nil }
        environment[config_variable] = config_home
        with_updater(environment:) do |directory, _|
          (directory/"fake-brew").write <<~SH
            #!/bin/sh
            printf '%s\\n' "$#{config_variable}"
          SH
          stdout, stderr, status = Open3.capture3(
            { "XDG_CONFIG_HOME" => nil, "HOMEBREW_XDG_CONFIG_HOME" => nil },
            (directory/"config/brew_autoupdate").to_s,
          )
          assert_predicate status, :success?, stderr
          assert_equal [config_home], stdout.lines(chomp: true).drop(1)
        end
      end
    end
  end

  def test_homebrew_reloads_brew_env_without_regenerating_the_updater
    assert_predicate Pathname.new(BREW), :absolute?
    Dir.mktmpdir("autoupdate-brew-env") do |config_home|
      homebrew_config = Pathname.new(config_home)/"homebrew"
      homebrew_config.mkpath
      env_file = homebrew_config/"brew.env"
      environment = { "XDG_CONFIG_HOME" => config_home, "HOMEBREW_CURL_RETRIES" => "2" }
      with_updater(environment:) do |directory, _|
        (directory/"fake-brew").write <<~SH
          #!/bin/sh
          exec #{BREW.shellescape} ruby -- -e 'puts ENV.fetch("HOMEBREW_CURL_RETRIES")'
        SH
        ["3", "4"].each do |retries|
          env_file.write "HOMEBREW_CURL_RETRIES=#{retries}\n"
          stdout, stderr, status = Open3.capture3(
            { "XDG_CONFIG_HOME" => nil, "HOMEBREW_XDG_CONFIG_HOME" => nil },
            (directory/"config/brew_autoupdate").to_s,
          )
          assert_predicate status, :success?, "#{stdout}\n#{stderr}"
          assert_equal [retries], stdout.lines(chomp: true).drop(1)
        end
      end
    end
  end

  private

  def with_updater(*options, environment: {})
    Dir.mktmpdir("autoupdate-start") do |directory|
      directory = Pathname.new(directory)
      fake_brew = directory/"fake-brew"
      fake_brew.write <<~SH
        #!/bin/sh
        printf '%s\\n' "${SUDO_ASKPASS-unset}"
      SH
      fake_brew.chmod 0755
      stdout, stderr, status = generate_updater(directory, *options, environment:)
      assert_predicate status, :success?, "#{stdout}\n#{stderr}"
      yield directory, stdout
    end
  end

  def generate_updater(directory, *options, environment: {})
    Open3.capture3(
      {
        "HOMEBREW_NO_ANALYTICS"   => "1",
        "HOMEBREW_NO_AUTO_UPDATE" => "1",
        "HOMEBREW_NO_COLOR"       => "1",
      },
      BREW, "ruby", "--", "-e", GENERATE_UPDATER, ROOT, directory.to_s, JSON.generate(environment),
      "start", "24h", *options,
      chdir: ROOT
    )
  end

  def brew_autoupdate(*arguments)
    Open3.capture3(
      ENVIRONMENT,
      BREW,
      "autoupdate",
      *arguments,
      chdir: ROOT,
    )
  end

  def brew_autoupdate_error(*arguments)
    stdout, stderr, status = brew_autoupdate(*arguments)
    ["#{stdout}\n#{stderr}", status]
  end
end

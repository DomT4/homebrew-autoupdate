# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "pathname"
require "tmpdir"

class CommandTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__).freeze
  BREW = ENV.fetch("HOMEBREW_BREW_FILE", "brew").freeze
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
    root, temporary_directory, pinentry = ARGV.shift(3)
    require File.join(root, "cmd/autoupdate")
    require File.join(root, "lib/autoupdate")
    directory = Pathname.new(temporary_directory)
    ENV["SUDO_ASKPASS"] = "/custom/askpass"
    Autoupdate::Core.define_singleton_method(:location) { directory/"config" }
    Autoupdate::Core.define_singleton_method(:logs) { (directory/"logs").to_s }
    Autoupdate::Core.define_singleton_method(:fallback_logs) { directory.to_s }
    Autoupdate::Core.define_singleton_method(:plist) { (directory/"agent.plist").to_s }
    Autoupdate::Core.define_singleton_method(:brew) { directory/"fake-brew" }
    Autoupdate::Notify.define_singleton_method(:command) { |mode:| ":" }
    Utils.define_singleton_method(:popen_read) { |*| "" }
    Utils::Path.define_singleton_method(:formula_any_version_installed?) do |_name|
      raise "Unexpected pinentry check" if pinentry == "forbidden"

      pinentry == "installed"
    end
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
    assert_includes stdout, "--pam"
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

  def test_pam_requires_sudo_and_sudo_still_requires_upgrade
    output, status = brew_autoupdate_error("start", "--upgrade", "--pam")
    refute_predicate status, :success?
    assert_includes output, "`--pam` cannot be passed without `--sudo`."

    output, status = brew_autoupdate_error("start", "--sudo", "--pam")
    refute_predicate status, :success?
    assert_includes output, "`--sudo` cannot be passed without `--upgrade`."
  end

  def test_pam_with_sudo_and_upgrade_reaches_interval_validation
    output, status = brew_autoupdate_error("start", "invalid", "--upgrade", "--sudo", "--pam")
    refute_predicate status, :success?
    assert_includes output, "The interval must be positive seconds"
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

  def test_pam_unsets_inherited_askpass_without_pinentry
    with_updater("--upgrade", "--sudo", "--pam", pinentry: "forbidden") do |directory, stdout|
      script = (directory/"config/brew_autoupdate").read
      assert_includes script, "unset SUDO_ASKPASS"
      refute_includes script, "export SUDO_ASKPASS="
      refute_path_exists directory/"config/brew_autoupdate_sudo_gui"
      assert_includes stdout, "Sudo authentication: native PAM"
      refute_includes stdout, "GUI sudo prompt: yes"
      assert_run_askpass directory, "unset"
    end
  end

  def test_sudo_without_pam_keeps_pinentry_helper
    with_updater("--upgrade", "--sudo", pinentry: "installed") do |directory, stdout|
      helper = directory/"config/brew_autoupdate_sudo_gui"
      assert_path_exists helper
      assert_includes helper.read, "pinentry-mac --no-global-grab --timeout 60"
      assert_equal 0555, helper.stat.mode & 0777
      assert_includes stdout, "GUI sudo prompt: yes"
      refute_includes stdout, "Sudo authentication: native PAM"
      assert_run_askpass directory, helper.to_s
    end
  end

  def test_without_sudo_preserves_custom_askpass
    with_updater(pinentry: "forbidden") do |directory, _|
      refute_path_exists directory/"config/brew_autoupdate_sudo_gui"
      assert_run_askpass directory, "/custom/askpass"
    end
  end

  def test_password_mode_still_requires_pinentry
    Dir.mktmpdir("autoupdate-start") do |directory|
      _stdout, stderr, status = generate_updater(directory, "--upgrade", "--sudo", pinentry: "missing")
      refute_predicate status, :success?
      assert_includes stderr, "`--sudo` requires"
      refute_path_exists Pathname.new(directory)/"config/brew_autoupdate"
    end
  end

  def test_pam_does_not_retry_a_failed_upgrade
    with_updater("--upgrade", "--sudo", "--pam", pinentry: "forbidden") do |directory, _|
      fake_brew = directory/"fake-brew"
      fake_brew.write <<~SH
        #!/bin/sh
        printf '%s\\n' "$*"
        if [ "$1" = upgrade ]; then exit 42; fi
      SH
      stdout, stderr, status = Open3.capture3((directory/"config/brew_autoupdate").to_s)
      assert_equal 42, status.exitstatus, stderr
      calls = stdout.lines(chomp: true).drop(1)
      assert_equal ["update", "upgrade --no-ask --formula -v"], calls
    end
  end

  private

  def with_updater(*options, pinentry:)
    Dir.mktmpdir("autoupdate-start") do |directory|
      directory = Pathname.new(directory)
      fake_brew = directory/"fake-brew"
      fake_brew.write <<~SH
        #!/bin/sh
        printf '%s\\n' "${SUDO_ASKPASS-unset}"
      SH
      fake_brew.chmod 0755
      stdout, stderr, status = generate_updater(directory, *options, pinentry:)
      assert_predicate status, :success?, "#{stdout}\n#{stderr}"
      yield directory, stdout
    end
  end

  def generate_updater(directory, *options, pinentry:)
    Open3.capture3(
      {
        "HOMEBREW_NO_ANALYTICS"   => "1",
        "HOMEBREW_NO_AUTO_UPDATE" => "1",
        "HOMEBREW_NO_COLOR"       => "1",
      },
      BREW, "ruby", "--", "-e", GENERATE_UPDATER, ROOT, directory.to_s, pinentry, "start", "24h", *options,
      chdir: ROOT,
    )
  end

  def assert_run_askpass(directory, expected)
    script = (directory/"config/brew_autoupdate").to_s
    _stdout, stderr, status = Open3.capture3("/bin/sh", "-n", script)
    assert_predicate status, :success?, stderr
    stdout, stderr, status = Open3.capture3({ "SUDO_ASKPASS" => "/runtime/askpass" }, script)
    assert_predicate status, :success?, stderr
    # The first line is the date; every fake brew invocation reports its environment.
    values = stdout.lines(chomp: true).drop(1)
    refute_empty values
    assert values.all? { |value| value == expected }, stdout
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

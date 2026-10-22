# frozen_string_literal: true

require "minitest/autorun"
require "open3"
# Required for standalone tests on Ruby 3.4.
require "pathname" # rubocop:disable Lint/RedundantRequireStatement
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
    root, temporary_directory, has_casks = ARGV.shift(3)
    require File.join(root, "cmd/autoupdate")
    require File.join(root, "lib/autoupdate")
    directory = Pathname.new(temporary_directory)
    caskroom = (HOMEBREW_PREFIX/"Caskroom").to_s
    Pathname.prepend(Module.new do
      define_method(:exist?) { to_s == caskroom ? has_casks == "true" : super() }
    end)
    ENV.delete("SUDO_ASKPASS")
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
    assert_includes stdout, "--formula"
    assert_includes stdout, "--cask"
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

  def test_package_type_options_require_upgrade
    %w[--formula --cask].each do |option|
      output, status = brew_autoupdate_error("start", option)
      refute_predicate status, :success?
      assert_includes output, "`#{option}` cannot be passed without `--upgrade`."

      output, status = brew_autoupdate_error("status", option)
      refute_predicate status, :success?
      assert_includes output, "The `status` subcommand does not accept the `#{option}` switch."
    end
  end

  def test_start_without_upgrade_remains_update_only
    assert_updater_calls [], ["update"], "no"
  end

  def test_default_and_explicit_both_upgrade_formulae_and_casks
    [[], %w[--formula --cask], %w[--cask --formula]].each do |options|
      assert_updater_calls ["--upgrade", *options],
                           ["update", "upgrade --no-ask --formula -v", "upgrade --no-ask --cask -v"],
                           "formulae and casks"
    end
  end

  def test_formula_only_does_not_upgrade_or_warn_about_casks
    assert_updater_calls %w[--upgrade --formula --cleanup],
                         ["update", "upgrade --no-ask --formula -v", "cleanup"], "formulae only"
  end

  def test_cask_only_does_not_upgrade_formulae
    assert_updater_calls %w[--upgrade --cask --greedy],
                         ["update", "upgrade --no-ask --cask -v --greedy"], "casks only"
  end

  def test_missing_caskroom_skips_cask_upgrades
    assert_updater_calls %w[--upgrade --cask], ["update"], "no", has_casks: false
    assert_updater_calls %w[--upgrade], ["update", "upgrade --no-ask --formula -v"],
                         "formulae only", has_casks: false
  end

  def test_package_selection_is_restricted_to_the_selected_type
    [
      [%w[--formula], " --formula", "formulae"],
      [%w[--cask], " --cask", "casks"],
      [%w[--formula --cask], "", "packages"],
      [[], "", "packages"],
    ].each do |options, flag, type|
      assert_updater_calls ["--upgrade", "--only=wget,firefox", "--greedy", *options],
                           ["update", "upgrade --no-ask#{flag} -v --greedy wget firefox"],
                           "selected #{type} (wget firefox)"
    end
  end

  def test_leaves_selection_with_formula_only_skips_casks
    assert_updater_calls %w[--upgrade --formula --leaves-only],
                         ["update", "leaves", "upgrade --no-ask --formula -v wget"], "top-level formulae only"
    assert_updater_calls %w[--upgrade --formula --cask --leaves-only],
                         ["update", "leaves", "upgrade --no-ask --formula -v wget", "upgrade --no-ask --cask -v"],
                         "top-level formulae and casks"
  end

  def test_cask_only_rejects_leaves_selection_before_starting
    output, status = brew_autoupdate_error("start", "--upgrade", "--cask", "--leaves-only")
    refute_predicate status, :success?
    assert_includes output, "`--leaves-only` requires formula upgrades"
  end

  private

  def assert_updater_calls(options, expected, summary, has_casks: true)
    Dir.mktmpdir("autoupdate-types") do |temporary_directory|
      directory = Pathname.new(temporary_directory)
      fake_brew = directory/"fake-brew"
      calls = directory/"calls"
      fake_brew.write <<~SH
        #!/bin/sh
        printf '%s\\n' "$*" >> "#{calls}"
        if [ "$1" = leaves ]; then printf '%s\\n' wget; fi
      SH
      fake_brew.chmod 0755
      stdout, stderr, status = Open3.capture3(
        ENVIRONMENT, BREW, "ruby", "--", "-e", GENERATE_UPDATER, ROOT,
        directory.to_s, has_casks.to_s, "start", "24h", *options
      )
      assert_predicate status, :success?, "#{stdout}\n#{stderr}"
      assert_includes stdout, "Upgrade: #{summary}\n"
      if summary.end_with?("formulae only")
        refute_includes stderr, "Casks that require"
      end
      script = (directory/"config/brew_autoupdate").to_s
      _stdout, stderr, status = Open3.capture3("/bin/sh", "-n", script)
      assert_predicate status, :success?, stderr
      _stdout, stderr, status = Open3.capture3(script)
      assert_predicate status, :success?, stderr
      assert_equal expected, calls.readlines(chomp: true)
    end
  end

  def brew_autoupdate(*arguments)
    Open3.capture3(
      ENVIRONMENT,
      BREW,
      "ruby", "--", "-e",
      'require "abstract_command"; require File.join(ARGV.shift, "cmd/autoupdate"); Homebrew::Cmd::Autoupdate.new(ARGV).run',
      ROOT, *arguments,
      chdir: ROOT
    )
  end

  def brew_autoupdate_error(*arguments)
    stdout, stderr, status = brew_autoupdate(*arguments)
    ["#{stdout}\n#{stderr}", status]
  end
end

# frozen_string_literal: true

require "minitest/autorun"
require "open3"

class CommandTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__).freeze
  BREW = ENV.fetch("HOMEBREW_BREW_FILE", "brew").freeze
  ENVIRONMENT = {
    "HOMEBREW_NO_ANALYTICS"        => "1",
    "HOMEBREW_NO_AUTO_UPDATE"      => "1",
    "HOMEBREW_NO_INSTALL_FROM_API" => "1",
    "HOMEBREW_NO_COLOR".           => "1",
    "LC_ALL"                       => "C",
  }.freeze

  def test_root_help_lists_subcommands
    stdout, stderr, status = brew_autoupdate("--help")

    assert_predicate status, :success?, stderr
    assert_includes stdout, "Subcommands:"
    assert_includes stdout, "start:"
    assert_includes stdout, "status:"
    assert_includes stdout, "logs:"
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
    assert_includes output, "The interval must be positive seconds or a duration"
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

  private

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

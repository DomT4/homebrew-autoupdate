# frozen_string_literal: true

require "minitest/autorun"
require "fileutils"
require "open3"
require "tempfile"
require "tmpdir"

class NotifierTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__).freeze
  SCRIPT = File.expand_path("../notifier/notify.sh", __dir__).freeze
  VERSION = File.read(File.join(ROOT, "VERSION")).strip.freeze

  def test_reports_an_up_to_date_run
    output, status = summarize(0, "==> Updating Homebrew...\nAlready up-to-date.\n")

    assert_predicate status, :success?
    assert_includes output, "Homebrew autoupdate completed"
    assert_includes output, "Homebrew is already up-to-date."
  end

  def test_reports_an_upgrade_count
    output, status = summarize(0, "==> Upgrading 3 outdated packages:\nfoo\nbar\n")

    assert_predicate status, :success?
    assert_includes output, "==> Upgrading 3 outdated packages:"
  end

  def test_reports_a_generic_success
    output, status = summarize(0, "Updated Homebrew from abc123 to def456.\n")

    assert_predicate status, :success?
    assert_includes output, "Homebrew was updated successfully."
  end

  def test_failure_uses_only_the_current_run_tail
    log = (1..7).map { |number| "failure line #{number}" }.join("\n")
    output, status = summarize(2, log)

    assert_predicate status, :success?
    assert_includes output, "Homebrew autoupdate failed"
    assert_includes output, "Exit status 2"
    refute_includes output, "failure line 1"
    assert_includes output, "failure line 7"
  end

  def test_error_mode_suppresses_success_notifications
    output, status = summarize(0, "Already up-to-date.", mode: "error")

    assert_predicate status, :success?
    assert_empty output
  end

  def test_committed_app_matches_the_shared_version
    plist = File.join(ROOT, "notifier/brew-autoupdate.app/Contents/Info.plist")
    output, status = Open3.capture2(
      "/usr/bin/plutil",
      "-extract",
      "CFBundleShortVersionString",
      "raw",
      plist,
    )

    assert_predicate status, :success?
    assert_equal VERSION, output.strip
  end

  def test_committed_app_has_a_valid_signature
    app = File.join(ROOT, "notifier/brew-autoupdate.app")
    _stdout, stderr, status = Open3.capture3(
      "/usr/bin/codesign",
      "--verify",
      "--deep",
      "--strict",
      app,
    )

    assert_predicate status, :success?, stderr
  end

  def test_committed_app_runs_as_a_background_ui_helper
    plist = File.join(ROOT, "notifier/brew-autoupdate.app/Contents/Info.plist")
    output, status = Open3.capture2(
      "/usr/bin/plutil",
      "-extract",
      "LSUIElement",
      "raw",
      plist,
    )

    assert_predicate status, :success?
    assert_equal "true", output.strip
  end

  def test_notifier_uses_the_native_executable
    source = File.read(File.join(ROOT, "notifier/notifier.swift"))
    shell = File.read(SCRIPT)

    assert_includes source, "UNUserNotificationCenter.current()"
    assert_includes source, "CommandLine.arguments[1]"
    assert_includes shell, "Contents/MacOS/brew-autoupdate-notifier"
    refute_includes shell, "/usr/bin/open"
  end

  def test_notifier_passes_the_summary_as_arguments
    output, status = invoke_fake_notifier(0, "Already up-to-date.\n")

    assert_predicate status, :success?
    assert_equal(
      [
        "<Homebrew autoupdate completed>",
        "<brew-autoupdate>",
        "<Homebrew is already up-to-date.>",
      ],
      output.lines(chomp: true),
    )
  end

  def test_notifier_failure_is_reported_without_failing_autoupdate
    output, status = invoke_fake_notifier(0, "Already up-to-date.\n", helper_status: 1)

    assert_predicate status, :success?
    assert_includes output, "Warning: notifier failed to display the update result."
  end

  private

  def summarize(exit_status, contents, mode: "always")
    Tempfile.create("autoupdate-notifier") do |log|
      log.write(contents)
      log.flush
      stdout, stderr, status = Open3.capture3(
        { "AUTUPDATE_NOTIFY_PRINT" => "1" },
        SCRIPT,
        exit_status.to_s,
        log.path,
        mode,
      )
      ["#{stdout}#{stderr}", status]
    end
  end

  def invoke_fake_notifier(exit_status, contents, helper_status: 0)
    Dir.mktmpdir("autoupdate-notifier-app") do |app|
      executable = File.join(app, "Contents/MacOS/brew-autoupdate-notifier")
      FileUtils.mkdir_p(File.dirname(executable))
      File.write(
        executable,
        <<~SH,
          #!/bin/bash
          printf '<%s>\\n' "$@"
          exit #{helper_status}
        SH
      )
      FileUtils.chmod(0755, executable)

      Tempfile.create("autoupdate-notifier") do |log|
        log.write(contents)
        log.flush
        stdout, stderr, status = Open3.capture3(
          SCRIPT,
          exit_status.to_s,
          log.path,
          "always",
          app,
        )
        return ["#{stdout}#{stderr}", status]
      end
    end
  end
end

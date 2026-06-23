# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/autoupdate/interval"

class IntervalTest < Minitest::Test
  def test_defaults_to_one_day
    assert_equal 86_400, Autoupdate::Interval.parse(nil)
  end

  def test_accepts_seconds_and_duration_suffixes
    assert_equal 3_600, Autoupdate::Interval.parse("3600")
    assert_equal 1_800, Autoupdate::Interval.parse("30m")
    assert_equal 43_200, Autoupdate::Interval.parse("12h")
    assert_equal 604_800, Autoupdate::Interval.parse("1w")
  end

  def test_rejects_zero_and_invalid_durations
    assert_raises(Autoupdate::Interval::InvalidIntervalError) do
      Autoupdate::Interval.parse("0")
    end
    assert_raises(Autoupdate::Interval::InvalidIntervalError) do
      Autoupdate::Interval.parse("tomorrow")
    end
  end

  def test_describes_the_largest_exact_unit
    assert_equal "1 hour", Autoupdate::Interval.describe(3_600)
    assert_equal "90 minutes", Autoupdate::Interval.describe(5_400)
    assert_equal "2 days", Autoupdate::Interval.describe(172_800)
  end
end

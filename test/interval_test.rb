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

  def test_accepts_a_24_hour_clock_time_as_a_daily_schedule
    result = Autoupdate::Interval.parse("00:00")
    assert_instance_of Autoupdate::Interval::CalendarTime, result
    assert_equal 0, result.hour
    assert_equal 0, result.minute

    result = Autoupdate::Interval.parse("9:05")
    assert_equal 9, result.hour
    assert_equal 5, result.minute

    result = Autoupdate::Interval.parse("23:59")
    assert_equal 23, result.hour
    assert_equal 59, result.minute
  end

  def test_rejects_invalid_clock_times
    assert_raises(Autoupdate::Interval::InvalidIntervalError) do
      Autoupdate::Interval.parse("24:00")
    end
    assert_raises(Autoupdate::Interval::InvalidIntervalError) do
      Autoupdate::Interval.parse("12:60")
    end
  end

  def test_describes_a_calendar_time_as_a_daily_schedule
    assert_equal "day at 00:00", Autoupdate::Interval.describe(Autoupdate::Interval::CalendarTime.new(0, 0))
    assert_equal "day at 09:05", Autoupdate::Interval.describe(Autoupdate::Interval::CalendarTime.new(9, 5))
  end
end

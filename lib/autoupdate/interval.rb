# frozen_string_literal: true

module Autoupdate
  module Interval
    DEFAULT_SECONDS = 86_400
    UNITS = {
      "s" => 1,
      "m" => 60,
      "h" => 60 * 60,
      "d" => 24 * 60 * 60,
      "w" => 7 * 24 * 60 * 60,
    }.freeze

    # A specific wall-clock time of day (24-hour, local time) to run daily at,
    # as opposed to a relative interval measured from when the job was loaded.
    CalendarTime = Struct.new(:hour, :minute) do
      def to_s
        format("%<hour>02d:%<minute>02d", hour: hour, minute: minute)
      end
    end

    class InvalidIntervalError < ArgumentError; end

    module_function

    def parse(value)
      return DEFAULT_SECONDS if value.nil?

      if (match = value.match(/\A([01]?\d|2[0-3]):([0-5]\d)\z/))
        return CalendarTime.new(match[1].to_i, match[2].to_i)
      end

      match = value.match(/\A(\d+)([smhdw]?)\z/i)
      raise InvalidIntervalError, invalid_interval_message unless match

      amount = match[1].to_i
      raise InvalidIntervalError, invalid_interval_message unless amount.positive?

      amount * UNITS.fetch(match[2].downcase, 1)
    end

    def describe(value)
      return "day at #{value}" if value.is_a?(CalendarTime)

      seconds = value
      amount, unit = [
        [UNITS.fetch("w"), "week"],
        [UNITS.fetch("d"), "day"],
        [UNITS.fetch("h"), "hour"],
        [UNITS.fetch("m"), "minute"],
        [UNITS.fetch("s"), "second"],
      ].find { |unit_seconds, _| (seconds % unit_seconds).zero? }

      count = seconds / amount
      "#{count} #{unit}#{"s" if count != 1}"
    end

    def invalid_interval_message
      "The interval must be positive seconds, a duration such as `30m`, `12h`, or `1d`, " \
        "or a 24-hour clock time such as `00:00` to run daily at that time."
    end
  end
end

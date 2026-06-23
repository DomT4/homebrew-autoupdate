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

    class InvalidIntervalError < ArgumentError; end

    module_function

    def parse(value)
      return DEFAULT_SECONDS if value.nil?

      match = value.match(/\A(\d+)([smhdw]?)\z/i)
      raise InvalidIntervalError, invalid_interval_message unless match

      amount = match[1].to_i
      raise InvalidIntervalError, invalid_interval_message unless amount.positive?

      amount * UNITS.fetch(match[2].downcase, 1)
    end

    def describe(seconds)
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
      "The interval must be positive seconds or a duration such as `30m`, `12h`, or `1d`."
    end
  end
end

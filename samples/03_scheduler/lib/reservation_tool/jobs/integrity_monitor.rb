# frozen_string_literal: true

require "time"

module ReservationTool
  module Jobs
    class IntegrityMonitor
      IntegrityError = Class.new(StandardError)

      def initialize(source:, notifier:, metrics:, clock: -> { Time.now })
        @source = source
        @notifier = notifier
        @metrics = metrics
        @clock = clock
      end

      def call
        reservations = Array(source.fetch)
        issues = []
        issues.concat(check_timeframe(reservations))
        issues.concat(check_overlap(reservations))
        issues.concat(check_stale(reservations))

        if issues.empty?
          metrics.increment(:integrity_pass)
          return :ok
        end

        metrics.increment(:integrity_fail)
        notifier.notify(issues)
        raise IntegrityError, issues.join(" / ")
      end

      private

      attr_reader :source, :notifier, :metrics, :clock

      def check_timeframe(reservations)
        reservations.each_with_object([]) do |reservation, acc|
          ends_at = parse_time(reservation[:ends_at] || reservation["ends_at"])
          starts_at = parse_time(reservation[:starts_at] || reservation["starts_at"])
          next if ends_at > starts_at

          acc << "Invalid timeframe: #{reservation[:id] || reservation['id']}"
        end
      end

      def check_overlap(reservations)
        booked = reservations.select { |r| (r[:status] || r["status"]) == "booked" }
        overlaps = []
        booked.combination(2) do |a, b|
          next unless same_resource?(a, b)
          next unless overlap?(a, b)

          overlaps << "Overlapping bookings: #{a[:id] || a['id']} vs #{b[:id] || b['id']}"
        end
        overlaps
      end

      def check_stale(reservations)
        now = clock.call
        reservations.each_with_object([]) do |reservation, acc|
          status = reservation[:status] || reservation["status"]
          ends_at = parse_time(reservation[:ends_at] || reservation["ends_at"])
          next unless status == "booked" && ends_at < now

          acc << "Stale booking not closed: #{reservation[:id] || reservation['id']}"
        end
      end

      def same_resource?(a, b)
        (a[:resource_name] || a["resource_name"]) == (b[:resource_name] || b["resource_name"])
      end

      def overlap?(a, b)
        a_start = parse_time(a[:starts_at] || a["starts_at"])
        a_end = parse_time(a[:ends_at] || a["ends_at"])
        b_start = parse_time(b[:starts_at] || b["starts_at"])
        b_end = parse_time(b[:ends_at] || b["ends_at"])

        a_start < b_end && b_start < a_end
      end

      def parse_time(value)
        return value if value.is_a?(Time)

        Time.parse(value.to_s)
      end
    end
  end
end


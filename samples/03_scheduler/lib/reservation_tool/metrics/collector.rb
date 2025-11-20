# frozen_string_literal: true

module ReservationTool
  module Metrics
    class Collector
      def initialize
        @counts = Hash.new(0)
      end

      def increment(key)
        counts[key] += 1
      end

      def get(key)
        counts[key]
      end

      def to_h
        counts.dup
      end

      private

      attr_reader :counts
    end
  end
end


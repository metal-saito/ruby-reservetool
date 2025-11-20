# frozen_string_literal: true

require "monitor"

module ReservationTool
  module Domain
    class MemoryRepository
      ConflictError = Class.new(StandardError)
      NotFoundError = Class.new(StandardError)

      def initialize(records: [])
        @records = records.dup
        @monitor = Monitor.new
      end

      def all
        synchronize { records.sort_by(&:starts_at) }
      end

      def add(reservation)
        synchronize do
          ensure_no_conflict!(reservation)
          records << reservation
        end
        reservation
      end

      def delete(id)
        synchronize do
          index = records.index { |r| r.id == id }
          raise NotFoundError, "Reservation #{id} not found" unless index

          records.delete_at(index)
        end
      end

      def next_id
        synchronize do
          format("RES-%04d", records.size + 1)
        end
      end

      private

      attr_reader :records, :monitor

      def synchronize(&block)
        monitor.synchronize(&block)
      end

      def ensure_no_conflict!(reservation)
        records.each do |existing|
          raise ConflictError, "予約が重複しています (#{existing.id})" if reservation.overlap?(existing)
        end
      end
    end
  end
end


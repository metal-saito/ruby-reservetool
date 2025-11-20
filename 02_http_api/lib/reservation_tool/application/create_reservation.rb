# frozen_string_literal: true

require "time"

module ReservationTool
  module Application
    class CreateReservation
      def initialize(repository:)
        @repository = repository
      end

      def call(payload)
        reservation = ReservationTool::Domain::Reservation.new(
          id: repository.next_id,
          user_name: fetch(payload, "user_name"),
          resource_name: fetch(payload, "resource_name"),
          starts_at: fetch_time(payload, "starts_at"),
          ends_at: fetch_time(payload, "ends_at")
        )

        repository.add(reservation)
      end

      private

      attr_reader :repository

      def fetch(payload, key)
        value = payload[key] || payload[key.to_sym]
        value = value.to_s.strip
        raise ReservationTool::Domain::Reservation::ValidationError, "#{key} は必須です" if value.empty?

        value
      end

      def fetch_time(payload, key)
        value = payload[key] || payload[key.to_sym]
        raise ReservationTool::Domain::Reservation::ValidationError, "#{key} は必須です" if value.nil?

        Time.parse(value.to_s)
      rescue ArgumentError
        raise ReservationTool::Domain::Reservation::ValidationError, "#{key} の形式が不正です"
      end
    end
  end
end


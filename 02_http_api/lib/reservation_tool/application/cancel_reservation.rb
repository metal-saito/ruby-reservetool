# frozen_string_literal: true

module ReservationTool
  module Application
    class CancelReservation
      def initialize(repository:)
        @repository = repository
      end

      def call(id)
        id = id.to_s.strip
        raise ArgumentError, "id is required" if id.empty?

        repository.delete(id)
      end

      private

      attr_reader :repository
    end
  end
end


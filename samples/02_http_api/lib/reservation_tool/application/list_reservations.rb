# frozen_string_literal: true

module ReservationTool
  module Application
    class ListReservations
      def initialize(repository:)
        @repository = repository
      end

      def call
        repository.all
      end

      private

      attr_reader :repository
    end
  end
end


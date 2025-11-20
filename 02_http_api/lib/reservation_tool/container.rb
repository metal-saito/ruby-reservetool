# frozen_string_literal: true

require_relative "domain/reservation"
require_relative "domain/memory_repository"
require_relative "application/create_reservation"
require_relative "application/list_reservations"
require_relative "application/cancel_reservation"

module ReservationTool
  class Container
    attr_reader :repository

    def initialize(repository: Domain::MemoryRepository.new)
      @repository = repository
    end

    def create_reservation
      @create_reservation ||= Application::CreateReservation.new(repository:)
    end

    def list_reservations
      @list_reservations ||= Application::ListReservations.new(repository:)
    end

    def cancel_reservation
      @cancel_reservation ||= Application::CancelReservation.new(repository:)
    end
  end
end


# frozen_string_literal: true

require "sinatra/base"
require "json"

require_relative "lib/reservation_tool/container"

module ReservationTool
  class HTTPAPI < Sinatra::Base
    set :show_exceptions, false
    set :container, ReservationTool::Container.new

    before do
      content_type :json
    end

    post "/reservations" do
      payload = parse_json(request.body.read)
      reservation = settings.container.create_reservation.call(payload)
      status 201
      serialize(reservation)
    rescue ReservationTool::Domain::Reservation::ValidationError => e
      halt 422, json_error(e.message)
    rescue ReservationTool::Domain::MemoryRepository::ConflictError => e
      halt 409, json_error(e.message)
    end

    get "/reservations" do
      reservations = settings.container.list_reservations.call
      serialize(reservations)
    end

    delete "/reservations/:id" do
      settings.container.cancel_reservation.call(params.fetch("id"))
      status 204
      ""
    rescue ReservationTool::Domain::MemoryRepository::NotFoundError
      halt 404, json_error("Reservation not found")
    end

    error JSON::ParserError do
      halt 400, json_error("Invalid JSON payload")
    end

    private

    def parse_json(raw)
      JSON.parse(raw || "")
    end

    def serialize(object)
      case object
      when Array
        JSON.dump(object.map(&:to_h))
      else
        JSON.dump(object.to_h)
      end
    end

    def json_error(message)
      JSON.dump(error: message)
    end
  end
end


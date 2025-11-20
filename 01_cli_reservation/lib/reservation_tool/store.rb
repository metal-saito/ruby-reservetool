# frozen_string_literal: true

require "yaml"
require "fileutils"
require "time"

require_relative "reservation"

module ReservationTool
  class Store
    ConflictError = Class.new(StandardError)
    NotFoundError = Class.new(StandardError)

    DEFAULT_PATH = File.expand_path("../../data/reservations.yml", __dir__)

    def initialize(path: DEFAULT_PATH)
      @path = path
      ensure_storage!
    end

    def all
      load_data.map do |raw|
        Reservation.new(
          raw.fetch("id"),
          raw.fetch("user_name"),
          raw.fetch("resource_name"),
          Time.parse(raw.fetch("starts_at")),
          Time.parse(raw.fetch("ends_at"))
        )
      end
    end

    def add(reservation)
      data = load_data
      ensure_no_overlap!(reservation, data)
      data << reservation.to_h
      write_data(data)
      reservation
    end

    def cancel(id)
      data = load_data
      removed = data.reject! { |entry| entry["id"] == id }
      raise NotFoundError, "Reservation #{id} not found" unless removed

      write_data(data)
    end

    private

    attr_reader :path

    def ensure_storage!
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, [].to_yaml) unless File.exist?(path)
    end

    def load_data
      YAML.safe_load(File.read(path), aliases: true) || []
    rescue Errno::ENOENT
      []
    end

    def write_data(data)
      File.write(path, data.to_yaml)
    end

    def ensure_no_overlap!(reservation, data)
      data.each do |entry|
        existing = Reservation.new(
          entry["id"],
          entry["user_name"],
          entry["resource_name"],
          Time.parse(entry["starts_at"]),
          Time.parse(entry["ends_at"])
        )
        raise ConflictError, "リソースが重複しています" if reservation.overlap?(existing)
      end
    end
  end
end


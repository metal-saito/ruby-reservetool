# frozen_string_literal: true

require "yaml"
require "fileutils"
require "time"

require_relative "reservation"

module ReservationTool
  # Store orchestrates persistence of Reservation entities while remaining
  # agnostic to the underlying persistence mechanism. Both the persistence layer
  # and the record mapper are dependency-injectable for easier customisation.
  class Store
    ConflictError = Class.new(StandardError)
    NotFoundError = Class.new(StandardError)

    DEFAULT_PATH = File.expand_path("../../data/reservations.yml", __dir__)

    def initialize(path: DEFAULT_PATH, persistence: nil, mapper: ReservationMapper.new)
      @persistence = persistence || YamlPersistence.new(path)
      @mapper = mapper
    end

    def all
      persistence.read.map { |raw| mapper.from_h(raw) }
    end

    def add(reservation)
      data = persistence.read
      ensure_no_overlap!(reservation, data)
      data << mapper.to_h(reservation)
      persistence.write(data)
      reservation
    end

    def cancel(id)
      data = persistence.read
      filtered = data.reject { |entry| entry["id"] == id }
      raise NotFoundError, "Reservation #{id} not found" if filtered.size == data.size

      persistence.write(filtered)
    end

    private

    attr_reader :persistence, :mapper

    def ensure_no_overlap!(reservation, data)
      data.each do |entry|
        existing = mapper.from_h(entry)
        raise ConflictError, "リソースが重複しています" if reservation.overlap?(existing)
      end
    end

    # Default YAML file persistence implementation. Provides a small, swappable
    # abstraction so alternative backends (databases, remote APIs, etc.) can be
    # implemented without changing the public Store API.
    class YamlPersistence
      def initialize(path)
        @path = path
        ensure_storage!
      end

      def read
        YAML.safe_load(File.read(path), aliases: true) || []
      rescue Errno::ENOENT
        []
      end

      def write(data)
        File.write(path, data.to_yaml)
      end

      attr_reader :path

      private

      def ensure_storage!
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, [].to_yaml) unless File.exist?(path)
      end
    end

    # Maps raw hashes to Reservation entities and vice versa. Extracted to make
    # it easier to support alternative schemas or additional attributes.
    class ReservationMapper
      def from_h(raw)
        Reservation.new(
          raw.fetch("id"),
          raw.fetch("user_name"),
          raw.fetch("resource_name"),
          Time.parse(raw.fetch("starts_at")),
          Time.parse(raw.fetch("ends_at"))
        )
      end

      def to_h(reservation)
        reservation.to_h
      end
    end
  end
end

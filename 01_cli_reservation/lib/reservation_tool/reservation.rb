# frozen_string_literal: true

require "securerandom"
require "time"

module ReservationTool
  # Reservation models a single booking and encapsulates validation rules for
  # time windows and resource usage.
  class Reservation
    ValidationError = Class.new(StandardError)

    attr_reader :id, :user_name, :resource_name, :starts_at, :ends_at

    def self.build(user_name:, resource_name:, starts_at:, ends_at:, id: nil)
      new(
        id || "RES-#{SecureRandom.hex(3).upcase}",
        user_name,
        resource_name,
        starts_at,
        ends_at
      )
    end

    def initialize(id, user_name, resource_name, starts_at, ends_at)
      @id = id
      @user_name = user_name
      @resource_name = resource_name
      @starts_at = starts_at
      @ends_at = ends_at
      validate!
    end

    def duration
      ends_at - starts_at
    end

    def overlap?(other)
      resource_name == other.resource_name &&
        starts_at < other.ends_at &&
        other.starts_at < ends_at
    end

    def to_h
      {
        "id" => id,
        "user_name" => user_name,
        "resource_name" => resource_name,
        "starts_at" => starts_at.iso8601,
        "ends_at" => ends_at.iso8601
      }
    end

    private

    def validate!
      raise ValidationError, "利用者名は必須です" if user_name.to_s.strip.empty?
      raise ValidationError, "リソース名は必須です" if resource_name.to_s.strip.empty?
      raise ValidationError, "開始・終了時刻は必須です" unless starts_at && ends_at
      raise ValidationError, "終了は開始より後である必要があります" unless ends_at > starts_at
      raise ValidationError, "最大 8 時間までです" if duration > 8 * 60 * 60
    end
  end
end


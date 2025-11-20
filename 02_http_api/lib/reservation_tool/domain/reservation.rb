# frozen_string_literal: true

require "time"

module ReservationTool
  module Domain
    class Reservation
      ValidationError = Class.new(StandardError)

      attr_reader :id, :user_name, :resource_name, :starts_at, :ends_at

      def initialize(id:, user_name:, resource_name:, starts_at:, ends_at:)
        @id = id
        @user_name = user_name.to_s.strip
        @resource_name = resource_name.to_s.strip
        @starts_at = coerce_time(starts_at)
        @ends_at = coerce_time(ends_at)
        validate!
      end

      def overlap?(other)
        resource_name == other.resource_name &&
          starts_at < other.ends_at &&
          other.starts_at < ends_at
      end

      def to_h
        {
          id: id,
          user_name: user_name,
          resource_name: resource_name,
          starts_at: starts_at.iso8601,
          ends_at: ends_at.iso8601
        }
      end

      private

      def coerce_time(value)
        return value if value.is_a?(Time)

        Time.parse(value.to_s)
      rescue ArgumentError
        raise ValidationError, "時刻形式が不正です: #{value.inspect}"
      end

      def duration
        ends_at - starts_at
      end

      def validate!
        raise ValidationError, "利用者名は必須です" if user_name.empty?
        raise ValidationError, "リソース名は必須です" if resource_name.empty?
        raise ValidationError, "終了時刻は開始より後である必要があります" unless ends_at > starts_at
        raise ValidationError, "最大 12 時間までです" if duration > 12 * 60 * 60
      end
    end
  end
end


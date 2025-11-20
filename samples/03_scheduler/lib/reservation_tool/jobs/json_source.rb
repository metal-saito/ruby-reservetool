# frozen_string_literal: true

require "json"

module ReservationTool
  module Jobs
    class JSONSource
      def initialize(path:)
        @path = path
      end

      def fetch
        JSON.parse(File.read(path), symbolize_names: true)
      end

      private

      attr_reader :path
    end
  end
end


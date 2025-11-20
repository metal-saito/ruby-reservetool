# frozen_string_literal: true

module ReservationTool
  module Notifiers
    class StdoutNotifier
      def initialize(io = $stdout)
        @io = io
      end

      def notify(messages)
        Array(messages).each do |message|
          io.puts("[Notifier] #{message}")
        end
      end

      private

      attr_reader :io
    end
  end
end


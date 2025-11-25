# frozen_string_literal: true

module ReservationTool
  class CLI
    # ErrorPresenter centralises how command exceptions are rendered. Handlers
    # can be registered for specific error classes, enabling custom messaging
    # without changing command implementations.
    class ErrorPresenter
      def initialize(io:, handlers: {})
        @io = io
        @handlers = normalise_handlers(handlers)
      end

      def present(error)
        handler = handlers.find { |handler_entry| error.is_a?(handler_entry.first) }&.last
        return false unless handler

        handler.call(error, io)
        true
      end

      private

      attr_reader :io, :handlers

      def normalise_handlers(raw_handlers)
        raw_handlers.each_with_object([]) do |(klass, handler), acc|
          raise ArgumentError, "handler must respond to #call" unless handler.respond_to?(:call)

          acc << [klass, handler]
        end
      end
    end
  end
end

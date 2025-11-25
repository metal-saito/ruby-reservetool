# frozen_string_literal: true

module ReservationTool
  class CLI
    module Commands
      # Cancels an existing reservation by ID.
      class Cancel
        attr_reader :name, :signature, :description

        def initialize(success_message: "予約をキャンセルしました: %{id}",
                       not_found_message: "指定 ID の予約は存在しません: %{id}",
                       usage_message: "usage: reserve cancel ID")
          @success_message = success_message
          @not_found_message = not_found_message
          @usage_message = usage_message
          @name = "cancel"
          @signature = "cancel ID"
          @description = "予約をキャンセルします"
        end

        def call(argv:, io:, store:, **)
          id = argv.first
          unless id
            io.puts(usage_message)
            return
          end

          store.cancel(id)
          io.puts format(success_message, id: id)
        rescue Store::NotFoundError
          io.puts format(not_found_message, id: id)
        end

        def aliases
          []
        end

        private

        attr_reader :success_message, :not_found_message, :usage_message
      end
    end
  end
end

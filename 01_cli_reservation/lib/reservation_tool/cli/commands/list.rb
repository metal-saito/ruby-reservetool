# frozen_string_literal: true

module ReservationTool
  class CLI
    module Commands
      # Lists reservations using the provided formatter and sort strategy.
      class List
        attr_reader :name, :signature, :description

        def initialize(formatter: ReservationTool::CLI::ReservationFormatter.new,
                       sort_strategy: ->(records) { records.sort_by(&:starts_at) },
                       empty_message: "予約はまだありません。")
          @formatter = formatter
          @sort_strategy = sort_strategy
          @empty_message = empty_message
          @name = "list"
          @signature = "list"
          @description = "予約を一覧表示します"
        end

        def call(argv:, io:, store:, **)
          reservations = sort_strategy.call(store.all)
          if reservations.empty?
            io.puts(empty_message)
            return
          end

          formatter.print(reservations, io: io)
        end

        def aliases
          []
        end

        private

        attr_reader :formatter, :sort_strategy, :empty_message
      end
    end
  end
end

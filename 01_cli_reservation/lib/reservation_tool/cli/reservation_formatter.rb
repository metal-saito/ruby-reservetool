# frozen_string_literal: true

module ReservationTool
  class CLI
    # Formats reservations for CLI output. Both the header and row formatting
    # callbacks can be overridden to customise how reservation data is rendered.
    class ReservationFormatter
      DEFAULT_HEADER = "ID       | 利用者 | リソース | 開始                     | 終了".freeze

      def initialize(header: DEFAULT_HEADER, row_formatter: nil)
        @header = header
        @row_formatter = row_formatter || method(:default_row)
      end

      def print(reservations, io:)
        io.puts header
        reservations.each do |reservation|
          io.puts row_formatter.call(reservation)
        end
      end

      private

      attr_reader :header, :row_formatter

      def default_row(reservation)
        format(
          "%-8s | %-6s | %-8s | %-24s | %-24s",
          reservation.id,
          reservation.user_name,
          reservation.resource_name,
          reservation.starts_at,
          reservation.ends_at
        )
      end
    end
  end
end

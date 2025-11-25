# frozen_string_literal: true

require "optparse"
require "time"

module ReservationTool
  class CLI
    module Commands
      # Handles reservation registration. The command object can be customised
      # by swapping the option parser factory, time parser, or success message.
      class Add
        REQUIRED_KEYS = %i[user_name resource_name starts_at ends_at].freeze

        attr_reader :name, :signature, :description

        def initialize(option_parser_factory: OptionParser, time_parser: ->(value) { Time.parse(value) },
                       success_message: "予約を登録しました: %{id}", error_heading: "引数エラー")
          @option_parser_factory = option_parser_factory
          @time_parser = time_parser
          @success_message = success_message
          @error_heading = error_heading
          @name = "add"
          @signature = "add --name NAME --resource RESOURCE --starts-at ISO8601 --ends-at ISO8601"
          @description = "予約を登録します"
        end

        def call(argv:, io:, store:, **)
          params = parse_options(argv, io: io)
          reservation = Reservation.build(**params)
          stored = store.add(reservation)
          io.puts format(success_message, id: stored.id)
        end

        def aliases
          []
        end

        private

        attr_reader :option_parser_factory, :time_parser, :success_message, :error_heading

        def parse_options(argv, io:)
          options = {}
          parser = build_parser(options)
          parser.parse!(argv)
          ensure_required_options!(options, parser: parser, io: io)
          options
        rescue OptionParser::ParseError => e
          handle_parse_failure(io: io, parser: parser, message: e.message)
        end

        def build_parser(options)
          option_parser_factory.new do |opt|
            opt.banner = "usage: reserve #{signature}"
            opt.on("--name NAME", "利用者名") { |value| options[:user_name] = value }
            opt.on("--resource RESOURCE", "リソース名") { |value| options[:resource_name] = value }
            opt.on("--starts-at TIME", "開始時刻 (ISO8601)") { |value| options[:starts_at] = time_parser.call(value) }
            opt.on("--ends-at TIME", "終了時刻 (ISO8601)") { |value| options[:ends_at] = time_parser.call(value) }
          end
        end

        def ensure_required_options!(options, parser:, io:)
          missing = REQUIRED_KEYS.reject { |key| options.key?(key) }
          return if missing.empty?

          io.puts "必須オプションが不足しています: #{missing.map { |key| option_label(key) }.join(", ")}"
          io.puts parser
          raise Reservation::ValidationError, error_heading
        end

        def handle_parse_failure(io:, parser:, message:)
          io.puts message
          io.puts parser
          raise Reservation::ValidationError, error_heading
        end

        def option_label(key)
          case key
          when :user_name then "--name"
          when :resource_name then "--resource"
          when :starts_at then "--starts-at"
          when :ends_at then "--ends-at"
          else
            key.to_s
          end
        end
      end
    end
  end
end

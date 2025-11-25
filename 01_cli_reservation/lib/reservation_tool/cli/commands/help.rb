# frozen_string_literal: true

module ReservationTool
  class CLI
    module Commands
      # Prints usage information for all registered commands. Aliases allow the
      # dispatcher to share a single help implementation across many triggers.
      class Help
        attr_reader :name, :signature, :description, :aliases

        def initialize(commands, aliases: %w[help --help -h])
          @commands = commands
          @aliases = aliases
          @name = "help"
          @signature = "help"
          @description = "コマンド一覧を表示します"
        end

        def call(argv:, io:, **)
          io.puts usage_text
        end

        def usage_text
          lines = @commands.map { |command| "  reserve #{command.signature}" }
          (['usage:'] + lines).join("\n") + "\n"
        end
      end
    end
  end
end

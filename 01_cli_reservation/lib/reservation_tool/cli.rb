# frozen_string_literal: true

require_relative "reservation"
require_relative "store"
require_relative "cli/reservation_formatter"
require_relative "cli/commands/add"
require_relative "cli/commands/cancel"
require_relative "cli/commands/help"
require_relative "cli/commands/list"

module ReservationTool
  # CLI provides a small command execution framework that can be extended by
  # registering additional command objects. Commands are responsible for their
  # own argument parsing and output, which keeps the dispatcher compact and
  # easier to customize.
  class CLI
    DEFAULT_COMMAND_FACTORY = lambda {
      [
        CLI::Commands::Add.new,
        CLI::Commands::List.new,
        CLI::Commands::Cancel.new
      ]
    }.freeze

    def initialize(io: $stdout, store: Store.new, commands: nil)
      @io = io
      @store = store
      command_set = commands || DEFAULT_COMMAND_FACTORY.call
      @commands = build_command_registry(command_set)
      @help_command = CLI::Commands::Help.new(@commands.values)
      register_help_aliases
    end

    # Executes the CLI with the given argv array. Unknown commands fall back to
    # the help output so that users always receive guidance.
    def run(argv)
      arguments = Array(argv).dup
      name = extract_command_name(arguments)
      command = resolve_command(name)
      command.call(argv: arguments, io: io, store: store)
    rescue Reservation::ValidationError => e
      io.puts "Validation error: #{e.message}"
    rescue Store::ConflictError => e
      io.puts "Conflict error: #{e.message}"
    end

    # Exposes the computed usage text so it can be surfaced by integrations or
    # tests without invoking the help command directly.
    def usage
      help_command.usage_text
    end

    private

    attr_reader :io, :store, :commands, :help_command

    def build_command_registry(command_set)
      case command_set
      when Hash
        command_set.each_with_object({}) do |(name, command), registry|
          register_command(registry, name.to_s, command)
        end
      else
        Array(command_set).each_with_object({}) do |command, registry|
          register_command(registry, command.name.to_s, command)
        end
      end
    end

    def extract_command_name(arguments)
      arguments.shift.to_s.strip
    end

    def resolve_command(name)
      return help_command if name.empty?

      commands.fetch(name) { help_command }
    end

    def register_help_aliases
      help_command.aliases.each do |alias_name|
        commands[alias_name] = help_command
      end
    end

    def register_command(registry, name, command)
      registry[name] = command
      return registry unless command.respond_to?(:aliases)

      command.aliases.each do |alias_name|
        next if alias_name.to_s == name

        registry[alias_name.to_s] = command
      end
      registry
    end
  end
end

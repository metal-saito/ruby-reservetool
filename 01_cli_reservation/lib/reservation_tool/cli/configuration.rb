# frozen_string_literal: true

module ReservationTool
  class CLI
    # Configuration collects dependencies and behaviour customisations for the
    # CLI. Callers can register commands, override error handling, and replace
    # the help command factory before the CLI is instantiated. The resulting
    # configuration is converted into the immutable runtime objects consumed by
    # the dispatcher.
    class Configuration
      CommandRegistration = Struct.new(:primary_name, :aliases, :command, keyword_init: true)
      BuiltState = Struct.new(:io, :store, :registry, :help_command, :error_presenter)

      attr_accessor :io, :store, :help_factory

      def initialize(io: $stdout, store: Store.new)
        @io = io
        @store = store
        @registrations = {}
        @command_order = []
        @help_factory = ->(commands) { CLI::Commands::Help.new(commands) }
        @error_handlers = default_error_handlers
      end

      def register_command(command, as: nil, aliases: nil)
        primary_name = (as || command.name).to_s
        alias_list = Array(aliases || (command.respond_to?(:aliases) ? command.aliases : [])).map(&:to_s)
        registration = CommandRegistration.new(primary_name: primary_name, aliases: alias_list, command: command)
        @registrations[primary_name] = registration
        @command_order.delete(primary_name)
        @command_order << primary_name
        self
      end

      def register_commands(*commands)
        commands.flatten.each { |command| register_command(command) }
        self
      end

      def register_default_commands
        register_commands(
          CLI::Commands::Add.new,
          CLI::Commands::List.new,
          CLI::Commands::Cancel.new
        )
        self
      end

      def on_error(error_class, message: nil, &block)
        handler = if block
                    block
                  elsif message
                    build_message_handler(message)
                  else
                    ->(error, io) { io.puts(error.message) }
                  end
        @error_handlers[error_class] = handler
        self
      end

      def empty?
        @command_order.empty?
      end

      def build
        registry = CommandRegistry.new(active_registrations)
        commands_for_help = registry.ordered_commands.dup
        help = help_factory.call(commands_for_help)
        registry.register(help, primary_name: help.name, aliases: help.aliases)
        help.update_commands(registry.ordered_commands) if help.respond_to?(:update_commands)

        BuiltState.new(
          io,
          store,
          registry,
          help,
          CLI::ErrorPresenter.new(io: io, handlers: @error_handlers)
        )
      end

      private

      def active_registrations
        @command_order.map { |name| @registrations.fetch(name) }
      end

      def build_message_handler(message)
        if message.include?("%{")
          ->(error, io) { io.puts(format(message, message: error.message, error: error)) }
        else
          ->(_error, io) { io.puts(message) }
        end
      end

      def default_error_handlers
        {
          Reservation::ValidationError => ->(error, io) { io.puts("Validation error: #{error.message}") },
          Store::ConflictError => ->(error, io) { io.puts("Conflict error: #{error.message}") }
        }
      end
    end
  end
end

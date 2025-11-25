# frozen_string_literal: true

require_relative "reservation"
require_relative "store"
require_relative "cli/command_registry"
require_relative "cli/configuration"
require_relative "cli/error_presenter"
require_relative "cli/reservation_formatter"
require_relative "cli/commands/add"
require_relative "cli/commands/cancel"
require_relative "cli/commands/help"
require_relative "cli/commands/list"

module ReservationTool
  # CLI now wraps command registration, error handling, and dispatching inside a
  # configurable pipeline. Consumers can add new commands, override existing
  # ones, and customise error responses without changing the dispatcher itself.
  class CLI
    def initialize(io: $stdout, store: Store.new, commands: nil, configuration: nil, &block)
      @configuration = configuration || CLI::Configuration.new
      @configuration.io = io
      @configuration.store = store

      register_initial_commands(commands)
      ensure_default_commands(commands)

      yield @configuration if block_given?

      finalize_configuration!
    end

    def run(argv)
      arguments = Array(argv).dup
      name = extract_command_name(arguments)
      command = registry.fetch(name) { help_command }
      command.call(argv: arguments, io: io, store: store)
    rescue StandardError => error
      handled = error_presenter.present(error)
      raise unless handled
    end

    def usage
      help_command.usage_text
    end

    private

    attr_reader :configuration, :registry, :help_command, :error_presenter
    attr_accessor :io, :store

    def finalize_configuration!
      built = configuration.build
      self.io = built.io
      self.store = built.store
      @registry = built.registry
      @help_command = built.help_command
      @error_presenter = built.error_presenter
    end

    def register_initial_commands(commands)
      return unless commands

      case commands
      when Hash
        commands.each { |name, command| configuration.register_command(command, as: name) }
      else
        Array(commands).each { |command| configuration.register_command(command) }
      end
    end

    def ensure_default_commands(commands)
      return unless commands.nil?
      return unless configuration.empty?

      configuration.register_default_commands
    end

    def extract_command_name(arguments)
      arguments.shift.to_s.strip
    end
  end
end

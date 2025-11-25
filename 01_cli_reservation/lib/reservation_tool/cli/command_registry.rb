# frozen_string_literal: true

module ReservationTool
  class CLI
    # CommandRegistry maintains the mapping between textual command names and
    # executable command objects. It normalises names, tracks insertion order for
    # help output, and supports alias registration so that callers can provide
    # multiple entry points for the same command implementation.
    class CommandRegistry
      Registration = Struct.new(:primary_name, :aliases, :command, keyword_init: true)

      def initialize(registrations = [])
        @lookup = {}
        @registrations = []
        Array(registrations).each { |registration| register_registration(registration) }
      end

      def register(command, primary_name:, aliases: [])
        registration = Registration.new(
          primary_name: primary_name.to_s,
          aliases: Array(aliases).map(&:to_s),
          command: command
        )
        register_registration(registration)
        self
      end

      def fetch(name, default = nil)
        key = normalise_key(name)
        if block_given?
          lookup.fetch(key) { yield }
        else
          lookup.fetch(key, default)
        end
      end

      def ordered_commands
        @registrations.map(&:command)
      end

      private

      attr_reader :lookup

      def register_registration(registration)
        register_name(registration.primary_name, registration.command)
        registration.aliases.each do |alias_name|
          next if alias_name == registration.primary_name

          register_name(alias_name, registration.command)
        end
        # Remove existing registration for the same command name to keep
        # ordering consistent when commands are replaced.
        @registrations.reject! { |existing| existing.primary_name == registration.primary_name }
        @registrations << registration
      end

      def register_name(name, command)
        lookup[normalise_key(name)] = command
      end

      def normalise_key(name)
        name.to_s
      end
    end
  end
end

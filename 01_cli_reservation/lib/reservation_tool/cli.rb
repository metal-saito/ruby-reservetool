# frozen_string_literal: true

require "optparse"
require "time"

require_relative "reservation"
require_relative "store"

module ReservationTool
  class CLI
    def initialize(io: $stdout, store: Store.new)
      @io = io
      @store = store
    end

    def run(argv)
      command = argv.shift
      case command
      when "add" then add(argv)
      when "list" then list
      when "cancel" then cancel(argv)
      else
        io.puts usage
      end
    rescue Reservation::ValidationError => e
      io.puts "Validation error: #{e.message}"
    rescue Store::ConflictError => e
      io.puts "Conflict error: #{e.message}"
    end

    private

    attr_reader :io, :store

    def add(argv)
      params = parse_add_options(argv)
      reservation = Reservation.build(**params)
      stored = store.add(reservation)
      io.puts "予約を登録しました: #{stored.id}"
    end

    def list
      records = store.all.sort_by(&:starts_at)
      if records.empty?
        io.puts "予約はまだありません。"
        return
      end

      io.puts "ID       | 利用者 | リソース | 開始                     | 終了"
      records.each do |r|
        io.puts format(
          "%-8s | %-6s | %-8s | %-24s | %-24s",
          r.id,
          r.user_name,
          r.resource_name,
          r.starts_at,
          r.ends_at
        )
      end
    end

    def cancel(argv)
      id = argv.first
      unless id
        io.puts "usage: reserve cancel ID"
        return
      end

      store.cancel(id)
      io.puts "予約をキャンセルしました: #{id}"
    rescue Store::NotFoundError
      io.puts "指定 ID の予約は存在しません: #{id}"
    end

    def parse_add_options(argv)
      options = {}
      parser = OptionParser.new do |opt|
        opt.banner = "usage: reserve add --name NAME --resource RESOURCE --starts-at ISO8601 --ends-at ISO8601"
        opt.on("--name NAME", "利用者名") { |v| options[:user_name] = v }
        opt.on("--resource RESOURCE", "リソース名") { |v| options[:resource_name] = v }
        opt.on("--starts-at TIME", "開始時刻 (ISO8601)") { |v| options[:starts_at] = Time.parse(v) }
        opt.on("--ends-at TIME", "終了時刻 (ISO8601)") { |v| options[:ends_at] = Time.parse(v) }
      end

      parser.parse!(argv)
      options
    rescue OptionParser::ParseError => e
      io.puts e.message
      io.puts parser
      raise Reservation::ValidationError, "引数エラー"
    end

    def usage
      <<~TEXT
        usage:
          reserve add --name NAME --resource RESOURCE --starts-at ISO8601 --ends-at ISO8601
          reserve list
          reserve cancel ID
      TEXT
    end
  end
end


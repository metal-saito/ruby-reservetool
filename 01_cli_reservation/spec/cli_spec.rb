# frozen_string_literal: true

require "stringio"
require "tmpdir"
require "fileutils"

require_relative "../lib/reservation_tool/cli"

RSpec.describe ReservationTool::CLI do
  let(:io) { StringIO.new }
  let(:tmpdir) { Dir.mktmpdir }
  let(:store_path) { File.join(tmpdir, "reservations.yml") }
  let(:store) { ReservationTool::Store.new(path: store_path) }
  let(:cli) { described_class.new(io: io, store: store) }

  after { FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir) }

  it "registers a reservation and prints the ID" do
    cli.run(["add", "--name", "Alice", "--resource", "Room-A", "--starts-at", "2025-01-02T09:00", "--ends-at", "2025-01-02T10:00"])

    io.rewind
    expect(io.string).to include("予約を登録しました: RES-")
    expect(store.all.size).to eq(1)
  end

  it "lists reservations in ascending order" do
    earlier = ReservationTool::Reservation.build(
      user_name: "Bob",
      resource_name: "Room-A",
      starts_at: Time.parse("2025-01-02T08:00"),
      ends_at: Time.parse("2025-01-02T09:00"),
      id: "RES-0001"
    )
    later = ReservationTool::Reservation.build(
      user_name: "Carol",
      resource_name: "Room-A",
      starts_at: Time.parse("2025-01-02T10:00"),
      ends_at: Time.parse("2025-01-02T11:00"),
      id: "RES-0002"
    )
    store.add(earlier)
    store.add(later)

    cli.run(["list"])

    io.rewind
    expect(io.string.lines.last).to include("RES-0002")
  end

  it "cancels a reservation" do
    reservation = ReservationTool::Reservation.build(
      user_name: "Dave",
      resource_name: "Room-B",
      starts_at: Time.parse("2025-01-02T12:00"),
      ends_at: Time.parse("2025-01-02T13:00"),
      id: "RES-9000"
    )
    store.add(reservation)

    cli.run(["cancel", reservation.id])

    io.rewind
    expect(io.string).to include("予約をキャンセルしました: RES-9000")
    expect(store.all).to be_empty
  end

  it "allows registering custom commands via configuration" do
    custom_command = Class.new do
      attr_reader :name, :signature, :description

      def initialize
        @name = "greet"
        @signature = "greet"
        @description = "追加のカスタムコマンドを実行します"
      end

      def aliases
        []
      end

      def call(argv:, io:, store:, **)
        io.puts("Hello from custom command!")
      end
    end.new

    configured_cli = described_class.new(io: io, store: store) do |config|
      config.register_command(custom_command)
    end

    configured_cli.run(["greet"])

    io.rewind
    expect(io.string).to include("Hello from custom command!")
  end

  it "supports overriding default error presentation" do
    configured_cli = described_class.new(io: io, store: store) do |config|
      config.on_error(
        ReservationTool::Reservation::ValidationError,
        message: "カスタムエラー: %{message}"
      )
    end

    configured_cli.run(["add"])

    io.rewind
    expect(io.string).to include("カスタムエラー: 引数エラー")
  end
end

# frozen_string_literal: true

require "tmpdir"
require "fileutils"

require_relative "../lib/reservation_tool/store"

RSpec.describe ReservationTool::Store do
  let(:tmpdir) { Dir.mktmpdir }
  let(:store_path) { File.join(tmpdir, "reservations.yml") }
  subject(:store) { described_class.new(path: store_path) }

  after { FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir) }

  it "persists reservations in YAML" do
    reservation = ReservationTool::Reservation.build(
      user_name: "Alice",
      resource_name: "Room-A",
      starts_at: Time.parse("2025-01-02T10:00"),
      ends_at: Time.parse("2025-01-02T11:00"),
      id: "RES-1"
    )

    store.add(reservation)

    reloaded = store.all
    expect(reloaded.map(&:id)).to eq(["RES-1"])
  end

  it "raises when reservation overlaps" do
    reservation = ReservationTool::Reservation.build(
      user_name: "Alice",
      resource_name: "Room-A",
      starts_at: Time.parse("2025-01-02T10:00"),
      ends_at: Time.parse("2025-01-02T11:00"),
      id: "RES-1"
    )
    overlapping = ReservationTool::Reservation.build(
      user_name: "Bob",
      resource_name: "Room-A",
      starts_at: Time.parse("2025-01-02T10:30"),
      ends_at: Time.parse("2025-01-02T11:30"),
      id: "RES-2"
    )
    store.add(reservation)

    expect { store.add(overlapping) }.to raise_error(described_class::ConflictError)
  end
end


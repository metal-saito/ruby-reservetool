# frozen_string_literal: true

require_relative "spec_helper"
require "reservation_tool/jobs/json_source"
require "reservation_tool/notifiers/stdout_notifier"

RSpec.describe ReservationTool::Jobs::IntegrityMonitor do
  let(:metrics) { ReservationTool::Metrics::Collector.new }
  let(:notifier) { instance_double("Notifier", notify: true) }
  let(:clock) { -> { Time.parse("2025-01-02T12:00:00Z") } }

  it "passes when reservations are healthy" do
    source = double(fetch: [
      { id: "RES-1", resource_name: "Room-A", starts_at: "2025-01-02T09:00:00Z", ends_at: "2025-01-02T10:00:00Z", status: "booked" }
    ])
    monitor = described_class.new(source: source, notifier: notifier, metrics: metrics, clock: clock)

    expect(monitor.call).to eq(:ok)
    expect(metrics.get(:integrity_pass)).to eq(1)
    expect(notifier).not_to have_received(:notify)
  end

  it "notifies and raises on integrity issues" do
    source = double(fetch: [
      { id: "RES-1", resource_name: "Room-A", starts_at: "2025-01-02T09:00:00Z", ends_at: "2025-01-02T08:00:00Z", status: "booked" },
      { id: "RES-2", resource_name: "Room-A", starts_at: "2025-01-02T09:30:00Z", ends_at: "2025-01-02T10:30:00Z", status: "booked" }
    ])
    monitor = described_class.new(source: source, notifier: notifier, metrics: metrics, clock: clock)

    expect { monitor.call }.to raise_error(described_class::IntegrityError)
    expect(metrics.get(:integrity_fail)).to eq(1)
    expect(notifier).to have_received(:notify)
  end
end


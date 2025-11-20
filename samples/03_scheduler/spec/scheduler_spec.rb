# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe ReservationTool::Scheduler do
  let(:logger) { Logger.new(StringIO.new) }
  let(:time0) { Time.parse("2025-01-02T09:00:00Z") }

  describe "#tick" do
    it "runs jobs when due" do
      calls = []
      scheduler = described_class.new(time_source: -> { time0 }, logger: logger, sleep_proc: ->(_) {})
      scheduler.every(5, name: "job") { calls << :called }

      scheduler.tick(time0)

      expect(calls).to eq([:called])
    end

    it "retries with backoff on failure" do
      attempts = 0
      timestamps = [
        time0,
        time0 + 4,
        time0 + 5,
        time0 + 20
      ]
      scheduler = described_class.new(time_source: -> { timestamps.shift || time0 }, logger: logger, sleep_proc: ->(_) {})
      scheduler.every(10, name: "job", retry_backoff: 5) do
        attempts += 1
        raise "boom" if attempts == 1
      end

      scheduler.tick(time0)          # failure
      scheduler.tick(time0 + 4)      # not yet due
      scheduler.tick(time0 + 5)      # retry succeeds

      expect(attempts).to eq(2)
    end
  end
end


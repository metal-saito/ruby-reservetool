# frozen_string_literal: true

require "rspec"
require "json"
require "stringio"
require "logger"
require "time"

SPEC_ROOT = File.expand_path(__dir__)
$LOAD_PATH.unshift(File.join(SPEC_ROOT, "..", "lib"))

require "reservation_tool/scheduler"
require "reservation_tool/jobs/integrity_monitor"
require "reservation_tool/metrics/collector"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end


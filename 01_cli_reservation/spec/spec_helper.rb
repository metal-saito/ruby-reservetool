# frozen_string_literal: true

require "rspec"
require "time"

SPEC_ROOT = File.expand_path(__dir__)
$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end


# frozen_string_literal: true

require "rack/test"
require "rspec"
require "json"

ENV["RACK_ENV"] = "test"

APP_ROOT = File.expand_path("..", __dir__)
$LOAD_PATH.unshift(File.join(APP_ROOT, "lib"))

require_relative "../app"

RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end


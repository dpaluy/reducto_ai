# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "reducto_ai"

require "minitest/autorun"
require "webmock/minitest"

module TestConfig
  def setup_config
    ReductoAI.reset_configuration!
    ReductoAI.configure do |config|
      config.api_key = "test-key"
      config.base_url = "https://api.example.com"
      config.logger = nil
    end
  end

  def teardown_config
    ReductoAI.reset_configuration!
  end
end

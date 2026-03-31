# frozen_string_literal: true

require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    ReductoAI.reset_configuration!
  end

  def teardown
    ReductoAI.reset_configuration!
  end

  def test_defaults
    config = ReductoAI.config
    assert_nil config.api_key
    assert_equal "https://platform.reducto.ai", config.base_url
    assert_equal 5, config.open_timeout
    assert_equal 30, config.read_timeout
    assert_nil config.webhook_secret
    assert_nil config.webhook_secret_resolver
  end

  def test_configure_block
    ReductoAI.configure do |config|
      config.api_key = "configured"
      config.logger = Logger.new($stdout)
    end

    assert_equal "configured", ReductoAI.config.api_key
    assert_instance_of Logger, ReductoAI.config.logger
  end
end

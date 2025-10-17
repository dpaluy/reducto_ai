# frozen_string_literal: true

require "test_helper"

class ClientTest < Minitest::Test
  include TestConfig

  def setup
    setup_config
  end

  def teardown
    teardown_config
  end

  def test_requires_api_key
    ReductoAI.reset_configuration!
    assert_raises(ArgumentError) { ReductoAI::Client.new }
  end

  def test_handles_unauthorized
    stub_request(:post, "https://api.example.com/parse")
      .to_return(
        status: 401,
        body: { error: "unauthorized" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    client = ReductoAI::Client.new
    error = assert_raises(ReductoAI::AuthenticationError) { client.post("/parse", {}) }
    assert_equal 401, error.status
  end

  def test_handles_network_error
    stub_request(:post, "https://api.example.com/parse").to_timeout

    client = ReductoAI::Client.new

    error = assert_raises(ReductoAI::NetworkError) do
      client.post("/parse", {})
    end
    assert_match(/Network error/, error.message)
  end

  # Configuration tests
  def test_accepts_custom_base_url
    client = ReductoAI::Client.new(base_url: "https://custom.example.com")
    assert_equal "https://custom.example.com", client.base_url
  end

  def test_uses_config_base_url_by_default
    ReductoAI.configure { |c| c.base_url = "https://configured.example.com" }
    client = ReductoAI::Client.new
    assert_equal "https://configured.example.com", client.base_url
  end

  def test_accepts_custom_timeouts
    client = ReductoAI::Client.new(open_timeout: 15, read_timeout: 45)
    assert_equal 15, client.open_timeout
    assert_equal 45, client.read_timeout
  end

  def test_uses_config_timeouts_by_default
    ReductoAI.configure do |c|
      c.open_timeout = 10
      c.read_timeout = 60
    end
    client = ReductoAI::Client.new
    assert_equal 10, client.open_timeout
    assert_equal 60, client.read_timeout
  end

  def test_accepts_custom_logger
    require "logger"
    custom_logger = Logger.new($stdout)
    client = ReductoAI::Client.new(logger: custom_logger)
    assert_same custom_logger, client.logger
  end

  def test_constructor_api_key_overrides_config
    ReductoAI.configure { |c| c.api_key = "config-key" }
    client = ReductoAI::Client.new(api_key: "custom-key")
    assert_equal "custom-key", client.api_key
  end
end

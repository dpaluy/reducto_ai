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
end

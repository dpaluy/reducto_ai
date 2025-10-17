# frozen_string_literal: true

require "test_helper"

module Actions
  class ParseTest < Minitest::Test
    include TestConfig

    def setup
      setup_config
      @client = ReductoAI::Client.new
    end

    def teardown
      teardown_config
    end

    def test_requires_input
      action = ReductoAI::Actions::Parse.new(client: @client)
      error = assert_raises(ArgumentError) { action.call(input: nil) }
      assert_equal "input is required", error.message
    end

    def test_builds_payload
      stub_request(:post, "https://api.example.com/parse")
        .with(body: { input: "doc", enhance: { agentic: true } }.to_json)
        .to_return(status: 200, body: { result: {} }.to_json, headers: { "Content-Type" => "application/json" })

      action = ReductoAI::Actions::Parse.new(client: @client)
      response = action.call(input: "doc", enhance: { agentic: true }, retrieval: nil)

      assert_equal({}, response["result"])
    end
  end
end

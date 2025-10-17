# frozen_string_literal: true

require "test_helper"

module Actions
  class ExtractTest < Minitest::Test
    include TestConfig

    def setup
      setup_config
      @client = ReductoAI::Client.new
    end

    def teardown
      teardown_config
    end

    def test_requires_instructions
      action = ReductoAI::Actions::Extract.new(client: @client)
      error = assert_raises(ArgumentError) { action.call(input: "doc", instructions: nil) }
      assert_equal "instructions are required", error.message
    end

    def test_builds_payload
      stub_request(:post, "https://api.example.com/extract")
        .with(body: { input: "job-1", instructions: { system_prompt: "Extract" } }.to_json)
        .to_return(
          status: 200,
          body: { result: { fields: [] } }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      action = ReductoAI::Actions::Extract.new(client: @client)
      response = action.call(input: "job-1", instructions: { system_prompt: "Extract" }, settings: nil)

      assert_equal [], response.dig("result", "fields")
    end
  end
end

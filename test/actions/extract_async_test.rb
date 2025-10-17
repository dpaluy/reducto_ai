# frozen_string_literal: true

require "test_helper"

module Actions
  class ExtractAsyncTest < Minitest::Test
    include TestConfig

    def setup
      setup_config
      @client = ReductoAI::Client.new
    end

    def teardown
      teardown_config
    end

    def test_requires_instructions
      action = ReductoAI::Actions::ExtractAsync.new(client: @client)
      error = assert_raises(ArgumentError) { action.call(input: "doc", instructions: nil) }
      assert_equal "instructions are required", error.message
    end

    def test_posts_payload
      stub_request(:post, "https://api.example.com/extract_async")
        .with(body: {
          input: "doc",
          instructions: { schema: {}, system_prompt: "Prompt" },
          async: { webhook: { url: "https://example.com" } }
        }.to_json)
        .to_return(
          status: 200,
          body: { job_id: "job-42" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      response = ReductoAI::Actions::ExtractAsync.new(client: @client).call(
        input: "doc",
        instructions: { schema: {}, system_prompt: "Prompt" },
        async: { webhook: { url: "https://example.com" } },
        settings: nil
      )

      assert_equal "job-42", response["job_id"]
    end
  end
end

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
      payload = { input: "doc", instructions: { schema: {}, system_prompt: "Prompt" },
                  async: { webhook: { url: "https://example.com" } } }
      stub_extract_request(payload, { job_id: "job-42" })

      response = ReductoAI::Actions::ExtractAsync.new(client: @client).call(**payload, settings: nil)

      assert_equal "job-42", response["job_id"]
    end

    private

    def stub_extract_request(payload, response_body)
      stub_request(:post, "https://api.example.com/extract_async")
        .with(body: payload.to_json)
        .to_return(status: 200, body: response_body.to_json, headers: { "Content-Type" => "application/json" })
    end
  end
end

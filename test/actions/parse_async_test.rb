# frozen_string_literal: true

require "test_helper"

module Actions
  class ParseAsyncTest < Minitest::Test
    include TestConfig

    def setup
      setup_config
      @client = ReductoAI::Client.new
    end

    def teardown
      teardown_config
    end

    def test_requires_input
      action = ReductoAI::Actions::ParseAsync.new(client: @client)
      error = assert_raises(ArgumentError) { action.call(input: nil) }
      assert_equal "input is required", error.message
    end

    def test_posts_payload
      stub_request(:post, "https://api.example.com/parse_async")
        .with(body: {
          input: "doc",
          async: { priority: true },
          enhance: { summarize_figures: true }
        }.to_json)
        .to_return(
          status: 200,
          body: { job_id: "job-1" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      response = ReductoAI::Actions::ParseAsync.new(client: @client).call(
        input: "doc",
        async: { priority: true },
        enhance: { summarize_figures: true },
        retrieval: nil
      )

      assert_equal "job-1", response["job_id"]
    end
  end
end

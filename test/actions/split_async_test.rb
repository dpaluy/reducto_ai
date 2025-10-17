# frozen_string_literal: true

require "test_helper"

module Actions
  class SplitAsyncTest < Minitest::Test
    include TestConfig

    def setup
      setup_config
      @client = ReductoAI::Client.new
    end

    def teardown
      teardown_config
    end

    def test_requires_arguments
      action = ReductoAI::Actions::SplitAsync.new(client: @client)
      assert_raises(ArgumentError) { action.call(input: nil, split_description: []) }
      assert_raises(ArgumentError) { action.call(input: "doc", split_description: []) }
    end

    def test_posts_payload
      stub_request(:post, "https://api.example.com/split_async")
        .with(body: {
          input: "doc",
          split_description: [{ name: "Intro" }],
          async: { priority: false }
        }.to_json)
        .to_return(
          status: 200,
          body: { job_id: "job-123" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      response = ReductoAI::Actions::SplitAsync.new(client: @client).call(
        input: "doc",
        split_description: [{ name: "Intro" }],
        async: { priority: false },
        split_rules: nil
      )

      assert_equal "job-123", response["job_id"]
    end
  end
end

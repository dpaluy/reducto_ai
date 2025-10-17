# frozen_string_literal: true

require "test_helper"

module Actions
  class PipelineAsyncTest < Minitest::Test
    include TestConfig

    def setup
      setup_config
      @client = ReductoAI::Client.new
    end

    def teardown
      teardown_config
    end

    def test_requires_arguments
      action = ReductoAI::Actions::PipelineAsync.new(client: @client)
      assert_raises(ArgumentError) { action.call(input: nil, pipeline_id: "pl") }
      assert_raises(ArgumentError) { action.call(input: "doc", pipeline_id: "") }
    end

    def test_posts_payload
      stub_request(:post, "https://api.example.com/pipeline_async")
        .with(body: {
          input: "doc",
          pipeline_id: "pl_1",
          async: { priority: false }
        }.to_json)
        .to_return(
          status: 200,
          body: { job_id: "job-pipe" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      response = ReductoAI::Actions::PipelineAsync.new(client: @client).call(
        input: "doc",
        pipeline_id: "pl_1",
        async: { priority: false },
        metadata: nil
      )

      assert_equal "job-pipe", response["job_id"]
    end
  end
end

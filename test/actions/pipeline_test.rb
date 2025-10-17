# frozen_string_literal: true

require "test_helper"

module Actions
  class PipelineTest < Minitest::Test
    include TestConfig

    def setup
      setup_config
      @client = ReductoAI::Client.new
    end

    def teardown
      teardown_config
    end

    def test_requires_fields
      action = ReductoAI::Actions::Pipeline.new(client: @client)
      assert_raises(ArgumentError) { action.call(input: nil, pipeline_id: "x") }
      assert_raises(ArgumentError) { action.call(input: "doc", pipeline_id: nil) }
      assert_raises(ArgumentError) { action.call(input: "doc", pipeline_id: "") }
    end

    def test_builds_payload
      stub_request(:post, "https://api.example.com/pipeline")
        .with(body: { input: "doc", pipeline_id: "pl_123" }.to_json)
        .to_return(status: 200, body: { result: { parse: {} } }.to_json, headers: { "Content-Type" => "application/json" })

      response = ReductoAI::Actions::Pipeline.new(client: @client).call(input: "doc", pipeline_id: "pl_123")

      assert_kind_of Hash, response["result"]
    end
  end
end

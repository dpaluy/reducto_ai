# frozen_string_literal: true

require "test_helper"

module Actions
  class SplitTest < Minitest::Test
    include TestConfig

    def setup
      setup_config
      @client = ReductoAI::Client.new
    end

    def teardown
      teardown_config
    end

    def test_validations
      action = ReductoAI::Actions::Split.new(client: @client)

      assert_raises(ArgumentError) { action.call(input: nil, split_description: []) }
      assert_raises(ArgumentError) { action.call(input: "doc", split_description: []) }
      assert_raises(ArgumentError) { action.call(input: "doc", split_description: [nil]) }
    end

    def test_builds_payload
      stub_request(:post, "https://api.example.com/split")
        .with(body: expected_body.to_json)
        .to_return(
          status: 200,
          body: { result: { splits: [] } }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      action = ReductoAI::Actions::Split.new(client: @client)
      response = action.call(**split_args)

      assert_equal [], response.dig("result", "splits")
    end

    def test_allows_default_split_rules
      stub_request(:post, "https://api.example.com/split")
        .with do |request|
          body = JSON.parse(request.body)
          body.key?("split_rules") == false && body["split_description"] == [{ "name" => "Intro" }]
        end
        .to_return(status: 200, body: { result: {} }.to_json, headers: { "Content-Type" => "application/json" })

      ReductoAI::Actions::Split.new(client: @client).call(
        input: "job-1",
        split_description: [{ name: "Intro" }]
      )
    end

    private

    def expected_body
      {
        input: "job-1",
        split_description: [{ name: "Intro" }],
        split_rules: "rules",
        settings: { table_cutoff: "truncate" }
      }
    end

    def split_args
      expected_body.merge(parsing: nil)
    end
  end
end

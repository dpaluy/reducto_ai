# frozen_string_literal: true

require "test_helper"

module Actions
  class GetJobsTest < Minitest::Test
    include TestConfig

    def setup
      setup_config
      @client = ReductoAI::Client.new
    end

    def teardown
      teardown_config
    end

    def test_fetches_jobs_with_defaults
      stub_request(:get, "https://api.example.com/jobs")
        .to_return(
          status: 200,
          body: { jobs: [{ "job_id" => "id" }], next_cursor: nil }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      response = ReductoAI::Actions::GetJobs.new(client: @client).call

      assert_equal "id", response.dig("jobs", 0, "job_id")
      assert_nil response["next_cursor"]
    end

    def test_validates_limit
      action = ReductoAI::Actions::GetJobs.new(client: @client)

      error = assert_raises(ArgumentError) { action.call(limit: "ten") }
      assert_equal "limit must be an Integer", error.message

      error = assert_raises(ArgumentError) { action.call(limit: 0) }
      assert_equal "limit must be between 1 and 500", error.message

      error = assert_raises(ArgumentError) { action.call(limit: 600) }
      assert_equal "limit must be between 1 and 500", error.message
    end

    def test_passes_params
      stub_request(:get, "https://api.example.com/jobs")
        .with(query: hash_including("exclude_configs" => "true", "cursor" => "abc", "limit" => "10"))
        .to_return(status: 200, body: { jobs: [] }.to_json, headers: { "Content-Type" => "application/json" })

      ReductoAI::Actions::GetJobs.new(client: @client).call(exclude_configs: true, cursor: "abc", limit: 10)

      assert_requested(:get, "https://api.example.com/jobs?cursor=abc&exclude_configs=true&limit=10", times: 1)
    end
  end
end

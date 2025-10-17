# frozen_string_literal: true

require "test_helper"

module Actions
  class CancelJobTest < Minitest::Test
    include TestConfig

    def setup
      setup_config
      @client = ReductoAI::Client.new
    end

    def teardown
      teardown_config
    end

    def test_requires_job_id
      action = ReductoAI::Actions::CancelJob.new(client: @client)

      error = assert_raises(ArgumentError) { action.call(job_id: nil) }
      assert_equal "job_id is required", error.message
    end

    def test_cancels_job
      stub_request(:post, "https://api.example.com/cancel/job-123")
        .to_return(
          status: 200,
          body: { status: "Cancelled" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      response = ReductoAI::Actions::CancelJob.new(client: @client).call(job_id: "job-123")

      assert_equal "Cancelled", response["status"]
    end
  end
end

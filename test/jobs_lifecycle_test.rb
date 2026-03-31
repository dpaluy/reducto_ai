# frozen_string_literal: true

require "test_helper"

class JobsLifecycleTest < Minitest::Test
  include TestConfig

  def setup
    setup_config
    @client = ReductoAI::Client.new
  end

  def teardown
    teardown_config
  end

  def test_normalize_status_maps_current_and_legacy_values
    status_expectations.each do |raw_status, normalized_status|
      assert_equal normalized_status, @client.jobs.normalize_status(raw_status)
    end

    assert_nil @client.jobs.normalize_status(nil)
  end

  def test_status_predicates_accept_hashes
    [
      [:pending?, { "status" => "Idle" }],
      [:in_progress?, { "status" => "running" }],
      [:completing?, { "status" => "Completing" }],
      [:completed?, { "status" => "succeeded" }],
      [:failed?, { "status" => "Failed" }],
      [:terminal?, { "status" => "Completed" }]
    ].each do |predicate, payload|
      assert @client.jobs.public_send(predicate, payload)
    end

    refute @client.jobs.terminal?("status" => "processing")
  end

  def test_wait_returns_completed_response
    stub_request(:get, "https://api.example.com/job/job-123")
      .to_return(
        { status: 200, body: { job_id: "job-123", status: "Pending" }.to_json },
        { status: 200, body: { job_id: "job-123", status: "Completed", result: { markdown: "ok" } }.to_json }
      )

    result = @client.jobs.wait(job_id: "job-123", interval: 0, timeout: 1)

    assert_equal "Completed", result["status"]
    assert_equal "ok", result.dig("result", "markdown")
  end

  def test_wait_raises_job_failed_error_by_default
    stub_request(:get, "https://api.example.com/job/job-123")
      .to_return(status: 200, body: { job_id: "job-123", status: "Failed", error: "boom" }.to_json)

    error = assert_raises(ReductoAI::JobFailedError) do
      @client.jobs.wait(job_id: "job-123", interval: 0, timeout: 1)
    end

    assert_equal "boom", error.body["error"]
  end

  def test_wait_returns_failed_response_when_raise_on_failure_is_false
    stub_request(:get, "https://api.example.com/job/job-123")
      .to_return(status: 200, body: { job_id: "job-123", status: "Failed", error: "boom" }.to_json)

    result = @client.jobs.wait(job_id: "job-123", interval: 0, timeout: 1, raise_on_failure: false)

    assert_equal "Failed", result["status"]
    assert_equal "boom", result["error"]
  end

  def test_wait_raises_job_timeout_error_when_attempt_limit_is_reached
    stub_request(:get, "https://api.example.com/job/job-123")
      .to_return(status: 200, body: { job_id: "job-123", status: "InProgress" }.to_json)

    error = assert_raises(ReductoAI::JobTimeoutError) do
      @client.jobs.wait(job_id: "job-123", interval: 0, max_attempts: 2)
    end

    assert_match(/job-123/, error.message)
  end

  def test_wait_raises_job_timeout_error_when_elapsed_timeout_is_exceeded
    stub_request(:get, "https://api.example.com/job/job-123")
      .to_return(status: 200, body: { job_id: "job-123", status: "InProgress" }.to_json)

    monotonic_times = [0.0, 0.0, 0.002]
    jobs = @client.jobs
    jobs.singleton_class.send(:define_method, :monotonic_time) { monotonic_times.shift || monotonic_times.last }

    error = assert_raises(ReductoAI::JobTimeoutError) do
      jobs.wait(job_id: "job-123", interval: 0, timeout: 0.001)
    end

    assert_match(/job-123/, error.message)
  ensure
    jobs.singleton_class.send(:remove_method, :monotonic_time)
  end

  def test_wait_raises_on_negative_interval
    error = assert_raises(ArgumentError) do
      @client.jobs.wait(job_id: "job-123", interval: -1)
    end
    assert_equal "interval must be non-negative", error.message
  end

  def test_wait_raises_on_negative_timeout
    error = assert_raises(ArgumentError) do
      @client.jobs.wait(job_id: "job-123", timeout: -1)
    end
    assert_equal "timeout must be non-negative", error.message
  end

  def test_wait_raises_on_zero_max_attempts
    error = assert_raises(ArgumentError) do
      @client.jobs.wait(job_id: "job-123", max_attempts: 0)
    end
    assert_equal "max_attempts must be positive", error.message
  end

  def test_wait_requires_timeout_or_max_attempts
    error = assert_raises(ArgumentError) do
      @client.jobs.wait(job_id: "job-123", interval: 0)
    end
    assert_equal "timeout or max_attempts is required", error.message
  end

  def test_wait_single_attempt_raises_timeout_when_not_terminal
    stub_request(:get, "https://api.example.com/job/job-123")
      .to_return(status: 200, body: { job_id: "job-123", status: "Pending" }.to_json)

    assert_raises(ReductoAI::JobTimeoutError) do
      @client.jobs.wait(job_id: "job-123", interval: 0, max_attempts: 1)
    end
  end

  def test_normalize_status_with_duck_typed_object
    status_object = Struct.new(:status).new("Completed")
    assert_equal "Completed", @client.jobs.normalize_status(status_object)
  end

  def test_jobs_list_normalizes_legacy_array_response
    stub_request(:get, "https://api.example.com/jobs")
      .to_return(status: 200, body: [{ job_id: "job-1" }].to_json)

    result = @client.jobs.list

    assert_nil result["next_cursor"]
    assert_equal "job-1", result.dig("results", 0, "job_id")
  end

  def test_jobs_list_returns_paginated_hash
    stub_request(:get, "https://api.example.com/jobs")
      .with(query: { status: "InProgress", limit: 10 })
      .to_return(status: 200, body: { results: [{ job_id: "job-1" }], next_cursor: "cursor-1" }.to_json)

    result = @client.jobs.list(status: "InProgress", limit: 10)

    assert_equal "cursor-1", result["next_cursor"]
    assert_equal "job-1", result.dig("results", 0, "job_id")
  end

  def test_configure_webhook_normalizes_hash_response
    stub_request(:post, "https://api.example.com/configure_webhook")
      .to_return(status: 200, body: { portal_url: "https://dashboard.svix.com/portal" }.to_json)

    result = @client.jobs.configure_webhook

    assert_equal "https://dashboard.svix.com/portal", result
  end

  def test_configure_webhook_returns_portal_url_string
    stub_request(:post, "https://api.example.com/configure_webhook")
      .to_return(status: 200, body: JSON.generate("https://dashboard.svix.com/portal"))

    result = @client.jobs.configure_webhook

    assert_equal "https://dashboard.svix.com/portal", result
  end

  def test_configure_webhook_raises_server_error_for_unexpected_response
    stub_request(:post, "https://api.example.com/configure_webhook")
      .to_return(status: 200, body: { unexpected: true }.to_json)

    error = assert_raises(ReductoAI::ServerError) do
      @client.jobs.configure_webhook
    end

    assert_equal({ "unexpected" => true }, error.body)
  end

  private

  def status_expectations
    {
      "Pending" => "Pending",
      "Idle" => "Pending",
      "InProgress" => "InProgress",
      "processing" => "InProgress",
      "running" => "InProgress",
      "Completing" => "Completing",
      "Completed" => "Completed",
      "complete" => "Completed",
      "succeeded" => "Completed",
      "Failed" => "Failed",
      "failed" => "Failed",
      "Mystery" => "Mystery"
    }
  end
end

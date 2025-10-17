# frozen_string_literal: true

require "test_helper"

class ResourcesTest < Minitest::Test
  include TestConfig

  def setup
    setup_config
    @client = ReductoAI::Client.new
  end

  def teardown
    teardown_config
  end

  # Parse resource tests
  def test_parse_sync_requires_input
    error = assert_raises(ArgumentError) { @client.parse.sync(input: nil) }
    assert_equal "input is required", error.message
  end

  def test_parse_sync_makes_post_request
    stub = stub_request(:post, "https://api.example.com/parse")
           .with(body: { input: "test" }.to_json)
           .to_return(status: 200, body: { result: "parsed" }.to_json)

    @client.parse.sync(input: "test")
    assert_requested stub
  end

  def test_parse_sync_with_options
    stub = stub_request(:post, "https://api.example.com/parse")
           .with(body: { input: "test", mode: "fast" }.to_json)
           .to_return(status: 200, body: {}.to_json)

    @client.parse.sync(input: "test", mode: "fast")
    assert_requested stub
  end

  def test_parse_async_requires_input
    error = assert_raises(ArgumentError) { @client.parse.async(input: nil) }
    assert_equal "input is required", error.message
  end

  def test_parse_async_makes_post_request
    stub = stub_request(:post, "https://api.example.com/parse_async")
           .with(body: { input: "test" }.to_json)
           .to_return(status: 200, body: { job_id: "123" }.to_json)

    @client.parse.async(input: "test")
    assert_requested stub
  end

  def test_parse_async_with_async_flag
    stub = stub_request(:post, "https://api.example.com/parse_async")
           .with(body: { input: "test", async: true }.to_json)
           .to_return(status: 200, body: { job_id: "123" }.to_json)

    @client.parse.async(input: "test", async: true)
    assert_requested stub
  end

  # Extract resource tests
  def test_extract_sync_requires_input
    error = assert_raises(ArgumentError) { @client.extract.sync(input: nil, instructions: "test") }
    assert_equal "input is required", error.message
  end

  def test_extract_sync_requires_instructions
    error = assert_raises(ArgumentError) { @client.extract.sync(input: "test", instructions: nil) }
    assert_equal "instructions are required", error.message
  end

  def test_extract_sync_rejects_empty_instructions
    error = assert_raises(ArgumentError) { @client.extract.sync(input: "test", instructions: "") }
    assert_equal "instructions are required", error.message
  end

  def test_extract_sync_makes_post_request
    stub = stub_request(:post, "https://api.example.com/extract")
           .with(body: { input: "test", instructions: { schema: "find dates" } }.to_json)
           .to_return(status: 200, body: { extracted: [] }.to_json)

    @client.extract.sync(input: "test", instructions: "find dates")
    assert_requested stub
  end

  def test_extract_sync_wraps_instructions_in_schema
    schema = { type: "object", properties: { date: { type: "string" } } }
    stub = stub_request(:post, "https://api.example.com/extract")
           .with(body: { input: "https://example.com/doc.pdf", instructions: { schema: schema } }.to_json)
           .to_return(status: 200, body: { extracted: [] }.to_json)

    @client.extract.sync(input: "https://example.com/doc.pdf", instructions: schema)
    assert_requested stub
  end

  def test_extract_sync_accepts_hash_input_with_url
    schema = { type: "object" }
    stub = stub_request(:post, "https://api.example.com/extract")
           .with(body: { input: "https://example.com/doc.pdf", instructions: { schema: schema } }.to_json)
           .to_return(status: 200, body: { extracted: [] }.to_json)

    @client.extract.sync(input: { url: "https://example.com/doc.pdf" }, instructions: schema)
    assert_requested stub
  end

  def test_extract_sync_accepts_string_url_input
    schema = { type: "object" }
    stub = stub_request(:post, "https://api.example.com/extract")
           .with(body: { input: "https://example.com/doc.pdf", instructions: { schema: schema } }.to_json)
           .to_return(status: 200, body: { extracted: [] }.to_json)

    @client.extract.sync(input: "https://example.com/doc.pdf", instructions: schema)
    assert_requested stub
  end

  def test_extract_sync_preserves_existing_schema_wrapper
    instructions = { schema: { type: "object" }, system_prompt: "Extract carefully" }
    stub = stub_request(:post, "https://api.example.com/extract")
           .with(body: { input: "https://example.com/doc.pdf", instructions: instructions }.to_json)
           .to_return(status: 200, body: { extracted: [] }.to_json)

    @client.extract.sync(input: "https://example.com/doc.pdf", instructions: instructions)
    assert_requested stub
  end

  def test_extract_async_makes_post_request
    stub = stub_request(:post, "https://api.example.com/extract_async")
           .with(body: { input: "test", instructions: { schema: "find dates" } }.to_json)
           .to_return(status: 200, body: { job_id: "456" }.to_json)

    @client.extract.async(input: "test", instructions: "find dates")
    assert_requested stub
  end

  def test_extract_async_transforms_input_and_instructions
    schema = { type: "object", properties: { field: { type: "string" } } }
    stub = stub_request(:post, "https://api.example.com/extract_async")
           .with(body: { input: "https://example.com/doc.pdf", instructions: { schema: schema } }.to_json)
           .to_return(status: 200, body: { job_id: "789" }.to_json)

    @client.extract.async(input: { url: "https://example.com/doc.pdf" }, instructions: schema)
    assert_requested stub
  end

  # Split resource tests
  def test_split_sync_requires_input
    error = assert_raises(ArgumentError) { @client.split.sync(input: nil) }
    assert_equal "input is required", error.message
  end

  def test_split_sync_makes_post_request
    stub = stub_request(:post, "https://api.example.com/split")
           .with(body: { input: "doc-id" }.to_json)
           .to_return(status: 200, body: { chunks: [] }.to_json)

    @client.split.sync(input: "doc-id")
    assert_requested stub
  end

  def test_split_async_makes_post_request
    stub = stub_request(:post, "https://api.example.com/split_async")
           .with(body: { input: "doc-id" }.to_json)
           .to_return(status: 200, body: { job_id: "789" }.to_json)

    @client.split.async(input: "doc-id")
    assert_requested stub
  end

  # Edit resource tests
  def test_edit_sync_requires_input_and_instructions
    assert_raises(ArgumentError) { @client.edit.sync(input: nil, instructions: "test") }
    assert_raises(ArgumentError) { @client.edit.sync(input: "test", instructions: nil) }
    assert_raises(ArgumentError) { @client.edit.sync(input: "test", instructions: "") }
  end

  def test_edit_sync_makes_post_request
    stub = stub_request(:post, "https://api.example.com/edit")
           .with(body: { document_url: "https://example.com/doc.pdf", edit_instructions: "fix typos" }.to_json)
           .to_return(status: 200, body: { edited: "text" }.to_json)

    @client.edit.sync(input: "https://example.com/doc.pdf", instructions: "fix typos")
    assert_requested stub
  end

  def test_edit_sync_accepts_hash_input_with_url
    stub = stub_request(:post, "https://api.example.com/edit")
           .with(body: { document_url: "https://example.com/doc.pdf", edit_instructions: "fix typos" }.to_json)
           .to_return(status: 200, body: { edited: "text" }.to_json)

    @client.edit.sync(input: { url: "https://example.com/doc.pdf" }, instructions: "fix typos")
    assert_requested stub
  end

  def test_edit_async_makes_post_request
    stub = stub_request(:post, "https://api.example.com/edit_async")
           .with(body: { document_url: "https://example.com/doc.pdf", edit_instructions: "fix typos" }.to_json)
           .to_return(status: 200, body: { job_id: "edit-1" }.to_json)

    @client.edit.async(input: "https://example.com/doc.pdf", instructions: "fix typos")
    assert_requested stub
  end

  # Pipeline resource tests
  def test_pipeline_sync_requires_input_and_steps
    assert_raises(ArgumentError) { @client.pipeline.sync(input: nil, steps: []) }
    assert_raises(ArgumentError) { @client.pipeline.sync(input: "test", steps: nil) }
    assert_raises(ArgumentError) { @client.pipeline.sync(input: "test", steps: []) }
  end

  def test_pipeline_sync_makes_post_request
    steps = [{ type: "parse" }]
    stub = stub_request(:post, "https://api.example.com/pipeline")
           .with(body: { input: "doc-id", steps: steps }.to_json)
           .to_return(status: 200, body: { result: "complete" }.to_json)

    @client.pipeline.sync(input: "doc-id", steps: steps)
    assert_requested stub
  end

  def test_pipeline_async_makes_post_request
    steps = [{ type: "parse" }]
    stub = stub_request(:post, "https://api.example.com/pipeline_async")
           .with(body: { input: "doc-id", steps: steps }.to_json)
           .to_return(status: 200, body: { job_id: "pipeline-1" }.to_json)

    @client.pipeline.async(input: "doc-id", steps: steps)
    assert_requested stub
  end

  # Jobs resource tests
  def test_jobs_version
    stub = stub_request(:get, "https://api.example.com/version")
           .to_return(status: 200, body: { version: "1.0.0" }.to_json)

    response = @client.jobs.version
    assert_requested stub
    assert_equal "1.0.0", response["version"]
  end

  def test_jobs_list
    stub = stub_request(:get, "https://api.example.com/jobs")
           .to_return(status: 200, body: [].to_json)

    @client.jobs.list
    assert_requested stub
  end

  def test_jobs_list_with_params
    stub = stub_request(:get, "https://api.example.com/jobs")
           .with(query: { status: "running", limit: 10 })
           .to_return(status: 200, body: [].to_json)

    @client.jobs.list(status: "running", limit: 10)
    assert_requested stub
  end

  def test_jobs_cancel_requires_job_id
    assert_raises(ArgumentError) { @client.jobs.cancel(job_id: nil) }
    assert_raises(ArgumentError) { @client.jobs.cancel(job_id: "") }
    assert_raises(ArgumentError) { @client.jobs.cancel(job_id: "  ") }
  end

  def test_jobs_cancel
    stub = stub_request(:post, "https://api.example.com/cancel/job-123")
           .to_return(status: 200, body: { cancelled: true }.to_json)

    response = @client.jobs.cancel(job_id: "job-123")
    assert_requested stub
    assert response["cancelled"]
  end

  def test_jobs_retrieve_requires_job_id
    assert_raises(ArgumentError) { @client.jobs.retrieve(job_id: nil) }
    assert_raises(ArgumentError) { @client.jobs.retrieve(job_id: "") }
  end

  def test_jobs_retrieve
    stub = stub_request(:get, "https://api.example.com/job/job-456")
           .to_return(status: 200, body: { id: "job-456", status: "complete" }.to_json)

    response = @client.jobs.retrieve(job_id: "job-456")
    assert_requested stub
    assert_equal "complete", response["status"]
  end

  def test_jobs_upload_requires_file
    error = assert_raises(ArgumentError) { @client.jobs.upload(file: nil) }
    assert_equal "file is required", error.message
  end

  def test_jobs_upload_rejects_nonexistent_file
    error = assert_raises(ArgumentError) { @client.jobs.upload(file: "/nonexistent/file.pdf") }
    assert_equal "file path does not exist", error.message
  end

  def test_jobs_upload_with_file_path
    Tempfile.create(["test", ".pdf"]) do |tempfile|
      tempfile.write("pdf content")
      tempfile.rewind

      stub = stub_request(:post, "https://api.example.com/upload")
             .with(query: { extension: "pdf" })
             .to_return(status: 200, body: { uploaded: true }.to_json)

      response = @client.jobs.upload(file: tempfile.path, extension: "pdf")
      assert_requested stub
      assert response["uploaded"]
    end
  end

  def test_jobs_upload_with_io_object
    Tempfile.create(["test", ".bin"]) do |tempfile|
      tempfile.write("binary data")
      tempfile.rewind

      stub = stub_request(:post, "https://api.example.com/upload")
             .to_return(status: 200, body: { uploaded: true }.to_json)

      response = @client.jobs.upload(file: tempfile)
      assert_requested stub
      assert response["uploaded"]
    end
  end

  def test_jobs_configure_webhook
    stub = stub_request(:post, "https://api.example.com/configure_webhook")
           .to_return(status: 200, body: { configured: true }.to_json)

    response = @client.jobs.configure_webhook
    assert_requested stub
    assert response["configured"]
  end

  # Resource accessor tests
  def test_client_parse_accessor
    assert_instance_of ReductoAI::Resources::Parse, @client.parse
  end

  def test_client_extract_accessor
    assert_instance_of ReductoAI::Resources::Extract, @client.extract
  end

  def test_client_split_accessor
    assert_instance_of ReductoAI::Resources::Split, @client.split
  end

  def test_client_edit_accessor
    assert_instance_of ReductoAI::Resources::Edit, @client.edit
  end

  def test_client_pipeline_accessor
    assert_instance_of ReductoAI::Resources::Pipeline, @client.pipeline
  end

  def test_client_jobs_accessor
    assert_instance_of ReductoAI::Resources::Jobs, @client.jobs
  end

  # Test resource caching
  def test_parse_resource_cached
    assert_same @client.parse, @client.parse
  end

  # Response parsing tests
  def test_parse_sync_returns_parsed_json
    stub_request(:post, "https://api.example.com/parse")
      .to_return(status: 200, body: { job_id: "123", status: "complete" }.to_json)

    result = @client.parse.sync(input: "test")
    assert_equal "123", result["job_id"]
    assert_equal "complete", result["status"]
  end

  def test_extract_sync_returns_result_array
    stub_request(:post, "https://api.example.com/extract")
      .with(body: { input: "test", instructions: { schema: "find" } }.to_json)
      .to_return(status: 200, body: { result: [{ field: "value" }] }.to_json)

    result = @client.extract.sync(input: "test", instructions: "find")
    assert_equal [{ "field" => "value" }], result["result"]
  end

  def test_jobs_list_returns_array
    stub_request(:get, "https://api.example.com/jobs")
      .to_return(status: 200, body: [{ id: "job-1" }, { id: "job-2" }].to_json)

    result = @client.jobs.list
    assert_equal 2, result.length
    assert_equal "job-1", result[0]["id"]
  end

  def test_jobs_retrieve_returns_job_details
    stub_request(:get, "https://api.example.com/job/job-456")
      .to_return(status: 200, body: { id: "job-456", status: "complete", result: {} }.to_json)

    result = @client.jobs.retrieve(job_id: "job-456")
    assert_equal "job-456", result["id"]
    assert_equal "complete", result["status"]
    assert result.key?("result")
  end

  def test_parse_sync_handles_empty_response
    stub_request(:post, "https://api.example.com/parse")
      .to_return(status: 200, body: "")

    result = @client.parse.sync(input: "test")
    assert_equal({}, result)
  end

  def test_parse_sync_handles_nil_response
    stub_request(:post, "https://api.example.com/parse")
      .to_return(status: 200, body: nil)

    result = @client.parse.sync(input: "test")
    assert_equal({}, result)
  end

  # Error handling tests
  def test_parse_sync_raises_authentication_error_on_401
    stub_request(:post, "https://api.example.com/parse")
      .to_return(status: 401, body: { error: "Invalid API key" }.to_json)

    error = assert_raises(ReductoAI::AuthenticationError) do
      @client.parse.sync(input: "test")
    end
    assert_match(/401/, error.message)
    assert_equal 401, error.status
  end

  def test_extract_sync_raises_client_error_on_404
    stub_request(:post, "https://api.example.com/extract")
      .with(body: { input: "test", instructions: { schema: "find" } }.to_json)
      .to_return(status: 404, body: { error: "Not found" }.to_json)

    error = assert_raises(ReductoAI::ClientError) do
      @client.extract.sync(input: "test", instructions: "find")
    end
    assert_match(/404/, error.message)
    assert_equal 404, error.status
  end

  def test_split_sync_raises_client_error_on_422
    stub_request(:post, "https://api.example.com/split")
      .to_return(status: 422, body: { error: "Invalid input" }.to_json)

    error = assert_raises(ReductoAI::ClientError) do
      @client.split.sync(input: "test")
    end
    assert_match(/422/, error.message)
    assert_equal 422, error.status
  end

  def test_parse_sync_raises_server_error_on_500
    stub_request(:post, "https://api.example.com/parse")
      .to_return(status: 500, body: { error: "Internal server error" }.to_json)

    error = assert_raises(ReductoAI::ServerError) do
      @client.parse.sync(input: "test")
    end
    assert_match(/500/, error.message)
    assert_equal 500, error.status
  end

  def test_extract_sync_raises_server_error_on_503
    stub_request(:post, "https://api.example.com/extract")
      .with(body: { input: "test", instructions: { schema: "find" } }.to_json)
      .to_return(status: 503, body: { error: "Service unavailable" }.to_json)

    error = assert_raises(ReductoAI::ServerError) do
      @client.extract.sync(input: "test", instructions: "find")
    end
    assert_match(/503/, error.message)
    assert_equal 503, error.status
  end

  def test_parse_sync_includes_error_body_in_exception
    stub_request(:post, "https://api.example.com/parse")
      .to_return(status: 400, body: { error: "Bad request", details: "Missing field" }.to_json)

    error = assert_raises(ReductoAI::ClientError) do
      @client.parse.sync(input: "test")
    end
    assert_equal({ "error" => "Bad request", "details" => "Missing field" }, error.body)
  end

  def test_parse_sync_handles_error_message_field
    stub_request(:post, "https://api.example.com/parse")
      .to_return(status: 400, body: { message: "Validation failed" }.to_json)

    error = assert_raises(ReductoAI::ClientError) do
      @client.parse.sync(input: "test")
    end
    assert_match(/Validation failed/, error.message)
  end

  def test_parse_sync_handles_plain_text_error_response
    stub_request(:post, "https://api.example.com/parse")
      .to_return(status: 500, body: "Internal Server Error")

    error = assert_raises(ReductoAI::ServerError) do
      @client.parse.sync(input: "test")
    end
    assert_match(/Internal Server Error/, error.message)
  end

  # Network error tests
  def test_parse_sync_raises_network_error_on_timeout
    stub_request(:post, "https://api.example.com/parse")
      .to_timeout

    error = assert_raises(ReductoAI::NetworkError) do
      @client.parse.sync(input: "test")
    end
    assert_match(/Network error/, error.message)
  end

  def test_extract_sync_raises_network_error_on_connection_failed
    stub_request(:post, "https://api.example.com/extract")
      .with(body: { input: "test", instructions: { schema: "find" } }.to_json)
      .to_raise(Faraday::ConnectionFailed.new("Failed to open TCP connection"))

    error = assert_raises(ReductoAI::NetworkError) do
      @client.extract.sync(input: "test", instructions: "find")
    end
    assert_match(/Network error/, error.message)
    assert_match(/Failed to open TCP connection/, error.message)
  end

  def test_jobs_retrieve_raises_network_error_on_timeout
    stub_request(:get, "https://api.example.com/job/job-123")
      .to_timeout

    error = assert_raises(ReductoAI::NetworkError) do
      @client.jobs.retrieve(job_id: "job-123")
    end
    assert_match(/Network error/, error.message)
  end
end

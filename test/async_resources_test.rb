# frozen_string_literal: true

require "test_helper"

class AsyncResourcesTest < Minitest::Test
  include TestConfig

  def setup
    setup_config
    @client = ReductoAI::Client.new
  end

  def teardown
    teardown_config
  end

  def test_parse_async_wraps_async_options
    async_options = {
      priority: false,
      webhook: { mode: "svix", channels: ["production"] },
      metadata: { document_id: "doc-123" }
    }

    stub = stub_request(:post, "https://api.example.com/parse_async")
           .with(body: { input: "test", async: async_options }.to_json)
           .to_return(status: 200, body: { job_id: "123" }.to_json)

    @client.parse.async(input: "test", async: async_options)

    assert_requested stub
  end

  def test_parse_async_accepts_legacy_true
    stub = stub_request(:post, "https://api.example.com/parse_async")
           .with(body: { input: "test", async: {} }.to_json)
           .to_return(status: 200, body: { job_id: "123" }.to_json)

    @client.parse.async(input: "test", async: true)

    assert_requested stub
  end

  def test_extract_async_wraps_async_options
    async_options = {
      priority: false,
      webhook: { mode: "svix", channels: ["production"] },
      metadata: { document_id: "doc-123" }
    }

    stub = stub_request(:post, "https://api.example.com/extract_async")
           .with(body: {
             input: "test",
             instructions: { schema: { total: "number" } },
             async: async_options
           }.to_json)
           .to_return(status: 200, body: { job_id: "456" }.to_json)

    @client.extract.async(input: "test", instructions: { total: "number" }, async: async_options)

    assert_requested stub
  end

  def test_split_async_wraps_async_options
    async_options = {
      priority: false,
      webhook: { mode: "svix", channels: ["production"] },
      metadata: { document_id: "doc-123" }
    }

    stub = stub_request(:post, "https://api.example.com/split_async")
           .with(body: { input: "doc-id", async: async_options }.to_json)
           .to_return(status: 200, body: { job_id: "789" }.to_json)

    @client.split.async(input: "doc-id", async: async_options)

    assert_requested stub
  end

  def test_pipeline_async_wraps_async_options
    async_options = {
      priority: false,
      webhook: { mode: "svix", channels: ["production"] },
      metadata: { document_id: "doc-123" }
    }
    steps = [{ type: "parse" }]

    stub = stub_request(:post, "https://api.example.com/pipeline_async")
           .with(body: { input: "doc-id", steps: steps, async: async_options }.to_json)
           .to_return(status: 200, body: { job_id: "pipeline-1" }.to_json)

    @client.pipeline.async(input: "doc-id", steps: steps, async: async_options)

    assert_requested stub
  end

  def test_edit_async_translates_async_options_to_top_level_keys
    stub = stub_request(:post, "https://api.example.com/edit_async")
           .with(body: edit_payload(edit_async_options).to_json)
           .to_return(status: 200, body: { job_id: "edit-1" }.to_json)

    @client.edit.async(input: "https://example.com/doc.pdf", instructions: "fix typos", async: edit_async_options)

    assert_requested stub
  end

  def test_edit_async_accepts_legacy_true
    stub = stub_request(:post, "https://api.example.com/edit_async")
           .with(body: {
             document_url: "https://example.com/doc.pdf",
             edit_instructions: "fix typos"
           }.to_json)
           .to_return(status: 200, body: { job_id: "edit-1" }.to_json)

    @client.edit.async(input: "https://example.com/doc.pdf", instructions: "fix typos", async: true)

    assert_requested stub
  end

  def test_edit_async_rejects_unsupported_async_options
    error = assert_raises(ArgumentError) do
      @client.edit.async(
        input: "https://example.com/doc.pdf",
        instructions: "fix typos",
        async: { metadata: { document_id: "doc-123" } }
      )
    end

    assert_equal "unsupported async options: metadata", error.message
  end

  def test_deep_compact_removes_nested_nils
    async_options = { priority: false, webhook: nil, metadata: { document_id: "doc-123" } }

    stub = stub_request(:post, "https://api.example.com/parse_async")
           .with(body: { input: "test", async: { priority: false, metadata: { document_id: "doc-123" } } }.to_json)
           .to_return(status: 200, body: { job_id: "123" }.to_json)

    @client.parse.async(input: "test", async: async_options)

    assert_requested stub
  end

  private

  def edit_async_options
    {
      priority: false,
      webhook: { mode: "svix", channels: ["production"] }
    }
  end

  def edit_payload(async_options = {})
    {
      document_url: "https://example.com/doc.pdf",
      edit_instructions: "fix typos",
      **async_options
    }
  end
end

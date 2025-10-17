# frozen_string_literal: true

require "test_helper"

module Actions
  class EditAsyncTest < Minitest::Test
    include TestConfig

    def setup
      setup_config
      @client = ReductoAI::Client.new
    end

    def teardown
      teardown_config
    end

    def test_requires_fields
      action = ReductoAI::Actions::EditAsync.new(client: @client)
      assert_raises(ArgumentError) { action.call(document_url: nil, edit_instructions: "Do it") }

      error = assert_raises(ArgumentError) do
        action.call(document_url: "doc", edit_instructions: "")
      end
      assert_equal "edit_instructions are required", error.message
    end

    def test_posts_payload
      payload = { document_url: "doc", edit_instructions: "Fix", priority: true }
      stub_edit_request(payload, { job_id: "job-edit" })

      response = ReductoAI::Actions::EditAsync.new(client: @client).call(**payload, form_schema: nil)

      assert_equal "job-edit", response["job_id"]
    end

    private

    def stub_edit_request(payload, response_body)
      stub_request(:post, "https://api.example.com/edit_async")
        .with(body: payload.to_json)
        .to_return(status: 200, body: response_body.to_json, headers: { "Content-Type" => "application/json" })
    end
  end
end

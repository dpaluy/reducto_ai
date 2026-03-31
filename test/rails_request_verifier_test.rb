# frozen_string_literal: true

require "test_helper"

class RailsRequestVerifierTest < Minitest::Test
  include TestConfig
  include WebhookFixture

  FakeRequest = Struct.new(:raw_post, :headers)

  def setup
    setup_config
  end

  def teardown
    teardown_config
  end

  def test_verify_returns_webhook_event
    secret, payload, headers = signed_webhook_payload(status: "Completed")
    ReductoAI.configure { |config| config.webhook_secret = secret }
    request = FakeRequest.new(payload, headers)

    event = ReductoAI::Rails::RequestVerifier.verify!(request)

    assert_equal "msg_123", event.svix_id
    assert_equal "job_123", event.job_id
    assert_equal "Completed", event.status
    assert_equal({ "document_id" => "doc-123" }, event.metadata)
    assert event.completed?
  end

  def test_verify_raises_when_signature_is_invalid
    secret, payload, headers = signed_webhook_payload(status: "Completed")
    ReductoAI.configure { |config| config.webhook_secret = secret }
    request = FakeRequest.new("#{payload}x", headers)

    assert_raises(ReductoAI::WebhookVerificationError) do
      ReductoAI::Rails::RequestVerifier.verify!(request)
    end
  end

  def test_event_parse_with_hash_input
    hash_payload = { "status" => "Completed", "job_id" => "job_abc" }
    event = ReductoAI::Webhooks::Event.parse(hash_payload)

    assert_equal "Completed", event.status
    assert_equal "job_abc", event.job_id
  end

  def test_event_parse_with_symbol_key_hash
    hash_payload = { status: "Failed", job_id: "job_xyz" }
    event = ReductoAI::Webhooks::Event.parse(hash_payload)

    assert_equal "Failed", event.status
    assert_equal "job_xyz", event.job_id
  end

  def test_event_to_h_returns_payload
    event = ReductoAI::Webhooks::Event.parse('{"status":"Completed","job_id":"job_1"}')

    assert_equal({ "status" => "Completed", "job_id" => "job_1" }, event.to_h)
  end

  def test_event_normalized_status
    event = ReductoAI::Webhooks::Event.parse('{"status":"succeeded","job_id":"j1"}')
    assert_equal "Completed", event.normalized_status
  end
end

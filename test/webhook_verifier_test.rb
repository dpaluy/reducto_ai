# frozen_string_literal: true

require "test_helper"

class WebhookVerifierTest < Minitest::Test
  include TestConfig
  include WebhookFixture

  def setup
    setup_config
  end

  def teardown
    teardown_config
  end

  def test_verify_returns_verified_payload
    secret, payload, headers = signed_webhook_payload(status: "Completed")

    ReductoAI.configure { |config| config.webhook_secret = secret }

    verified = ReductoAI::Webhooks::Verifier.verify!(payload: payload, headers: headers)

    assert_equal "Completed", verified[:status]
    assert_equal "job_123", verified[:job_id]
  end

  def test_verify_raises_on_invalid_signature
    secret, payload, headers = signed_webhook_payload(status: "Completed")
    ReductoAI.configure { |config| config.webhook_secret = secret }

    error = assert_raises(ReductoAI::WebhookVerificationError) do
      ReductoAI::Webhooks::Verifier.verify!(payload: "#{payload}x", headers: headers)
    end

    assert_match(/signature/i, error.message)
  end

  def test_verify_raises_on_stale_timestamp
    secret, payload, headers = signed_webhook_payload(status: "Completed", timestamp: Time.now.to_i - 301)
    ReductoAI.configure { |config| config.webhook_secret = secret }

    error = assert_raises(ReductoAI::WebhookVerificationError) do
      ReductoAI::Webhooks::Verifier.verify!(payload: payload, headers: headers)
    end

    assert_match(/timestamp/i, error.message)
  end

  def test_verify_raises_when_webhook_secret_is_missing
    _secret, payload, headers = signed_webhook_payload(status: "Completed")
    ReductoAI.configure { |config| config.webhook_secret = nil }

    error = assert_raises(ReductoAI::WebhookVerificationError) do
      ReductoAI::Webhooks::Verifier.verify!(payload: payload, headers: headers)
    end

    assert_equal "webhook secret is required", error.message
  end

  def test_verify_raises_on_wrong_secret
    _secret, payload, headers = signed_webhook_payload(status: "Completed")
    wrong_secret = "whsec_#{Base64.strict_encode64("wrong-secret")}"
    ReductoAI.configure { |config| config.webhook_secret = wrong_secret }

    assert_raises(ReductoAI::WebhookVerificationError) do
      ReductoAI::Webhooks::Verifier.verify!(payload: payload, headers: headers)
    end
  end

  def test_verify_uses_secret_resolver_when_configured
    secret, payload, headers = signed_webhook_payload(status: "Completed")
    resolved_headers = nil

    ReductoAI.configure do |config|
      config.webhook_secret = nil
      config.webhook_secret_resolver = lambda do |incoming_headers|
        resolved_headers = incoming_headers
        secret
      end
    end

    verified = ReductoAI::Webhooks::Verifier.verify!(payload: payload, headers: headers)

    assert_equal headers["svix-id"], resolved_headers["svix-id"]
    assert_equal "Completed", verified[:status]
  end
end

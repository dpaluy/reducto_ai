# frozen_string_literal: true

module WebhookFixture
  def signed_webhook_payload(status:, timestamp: Time.now.to_i)
    secret = "whsec_#{Base64.strict_encode64("super-secret")}"
    payload = JSON.generate(status: status, job_id: "job_123", metadata: { document_id: "doc-123" })
    message_id = "msg_123"
    signature = Svix::Webhook.new(secret).sign(message_id, timestamp.to_s, payload)
    headers = { "svix-id" => message_id, "svix-timestamp" => timestamp.to_s, "svix-signature" => signature }
    [secret, payload, headers]
  end
end

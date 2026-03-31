# frozen_string_literal: true

require "svix"

module ReductoAI
  module Webhooks
    class Verifier
      class << self
        def verify!(payload:, headers:, secret: nil)
          normalized_headers = normalize_headers(headers)
          resolved_secret = resolve_secret(secret, normalized_headers)

          raise WebhookVerificationError, "webhook secret is required" if resolved_secret.to_s.strip.empty?

          build_webhook(resolved_secret).verify(payload.to_s, normalized_headers)
        rescue Svix::WebhookVerificationError => e
          raise WebhookVerificationError, e.message
        end

        private

        def build_webhook(secret)
          Svix::Webhook.new(secret)
        rescue ArgumentError => e
          raise WebhookVerificationError, "invalid webhook secret format: #{e.message}"
        end

        def resolve_secret(secret, headers)
          return secret unless secret.nil? || secret.to_s.strip.empty?

          configuration = ReductoAI.config
          return configuration.webhook_secret_resolver.call(headers) if configuration.webhook_secret_resolver

          configuration.webhook_secret
        end

        def normalize_headers(headers)
          return {} if headers.nil?

          headers.each_with_object({}) do |(key, value), normalized|
            normalized[key.to_s.downcase] = value.to_s
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module ReductoAI
  module Rails
    class RequestVerifier
      WEBHOOK_HEADERS = %w[svix-id svix-timestamp svix-signature].freeze
      private_constant :WEBHOOK_HEADERS

      class << self
        def verify!(request, secret: nil)
          payload = request.raw_post
          headers = extract_webhook_headers(request)
          verified_payload = Webhooks::Verifier.verify!(payload: payload, headers: headers, secret: secret)

          Webhooks::Event.parse(verified_payload, headers: headers)
        end

        private

        def extract_webhook_headers(request)
          WEBHOOK_HEADERS.each_with_object({}) do |key, h|
            value = request.headers[key]
            h[key] = value.to_s if value
          end
        end
      end
    end
  end
end

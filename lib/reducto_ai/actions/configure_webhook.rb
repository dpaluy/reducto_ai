# frozen_string_literal: true

module ReductoAI
  module Actions
    class ConfigureWebhook
      def initialize(client: ReductoAI.client)
        @client = client
      end

      # API currently expects no body
      def call
        client.request(:post, "/configure_webhook")
      end

      private

      attr_reader :client
    end
  end
end

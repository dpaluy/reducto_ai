# frozen_string_literal: true

module ReductoAI
  module Actions
    class GetVersion
      def initialize(client: ReductoAI.client)
        @client = client
      end

      def call
        client.request(:get, "/version")
      end

      private

      attr_reader :client
    end
  end
end

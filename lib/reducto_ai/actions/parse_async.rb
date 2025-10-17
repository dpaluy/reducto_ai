# frozen_string_literal: true

module ReductoAI
  module Actions
    class ParseAsync
      def initialize(client: ReductoAI.client)
        @client = client
      end

      def call(input:, async: nil, **options)
        raise ArgumentError, "input is required" if input.nil?

        payload = { input: }
        payload[:async] = async unless async.nil?
        payload.merge!(options.compact)

        client.post("/parse_async", payload)
      end

      private

      attr_reader :client
    end
  end
end

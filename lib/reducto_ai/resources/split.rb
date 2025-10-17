# frozen_string_literal: true

module ReductoAI
  module Resources
    class Split
      def initialize(client)
        @client = client
      end

      def sync(input:, **options)
        raise ArgumentError, "input is required" if input.nil?

        normalized_input = normalize_input(input)
        payload = { input: normalized_input, **options }.compact
        @client.post("/split", payload)
      end

      def async(input:, async: nil, **options)
        raise ArgumentError, "input is required" if input.nil?

        normalized_input = normalize_input(input)
        payload = { input: normalized_input }
        payload[:async] = async unless async.nil?
        payload.merge!(options.compact)

        @client.post("/split_async", payload)
      end

      private

      def normalize_input(input)
        return input unless input.is_a?(Hash)

        input[:url] || input["url"] || input
      end
    end
  end
end

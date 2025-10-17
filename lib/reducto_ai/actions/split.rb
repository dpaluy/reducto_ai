# frozen_string_literal: true

module ReductoAI
  module Actions
    class Split
      def initialize(client: ReductoAI.client)
        @client = client
      end

      def call(input:, split_description:, split_rules: nil, **options)
        validate!(input, split_description)

        payload = {
          input:,
          split_description: normalize_split_description(split_description)
        }

        payload[:split_rules] = split_rules unless blank?(split_rules)
        payload.merge!(options.compact)

        client.post("/split", payload)
      end

      private

      attr_reader :client

      def validate!(input, split_description)
        raise ArgumentError, "input is required" if input.nil?
        raise ArgumentError, "split_description is required" if Array(split_description).compact.empty?
      end

      def normalize_split_description(value)
        Array(value).compact.tap do |descriptions|
          raise ArgumentError, "split_description is required" if descriptions.empty?
        end
      end

      def blank?(value)
        return true if value.nil?
        return value.empty? if value.respond_to?(:empty?)

        false
      end
    end
  end
end

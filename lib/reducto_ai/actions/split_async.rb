# frozen_string_literal: true

module ReductoAI
  module Actions
    class SplitAsync
      def initialize(client: ReductoAI.client)
        @client = client
      end

      def call(input:, split_description:, async: nil, **options)
        validate!(input, split_description)

        payload = {
          input:,
          split_description: normalize_split_description(split_description)
        }
        payload[:async] = async unless async.nil?
        payload.merge!(options.compact)

        client.post("/split_async", payload)
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
    end
  end
end

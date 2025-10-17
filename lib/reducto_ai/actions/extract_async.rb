# frozen_string_literal: true

module ReductoAI
  module Actions
    class ExtractAsync
      def initialize(client: ReductoAI.client)
        @client = client
      end

      def call(input:, instructions:, async: nil, **options)
        validate!(input, instructions)

        payload = {
          input:,
          instructions: instructions
        }
        payload[:async] = async unless async.nil?
        payload.merge!(options.compact)

        client.post("/extract_async", payload)
      end

      private

      attr_reader :client

      def validate!(input, instructions)
        raise ArgumentError, "input is required" if input.nil?
        raise ArgumentError, "instructions are required" if blank?(instructions)
      end

      def blank?(value)
        return true if value.nil?
        return value.empty? if value.respond_to?(:empty?)

        false
      end
    end
  end
end

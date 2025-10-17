# frozen_string_literal: true

module ReductoAI
  module Resources
    class Extract
      def initialize(client)
        @client = client
      end

      def sync(input:, instructions:, **options)
        raise ArgumentError, "input is required" if input.nil?
        if instructions.nil? || (instructions.respond_to?(:empty?) && instructions.empty?)
          raise ArgumentError, "instructions are required"
        end

        payload = build_payload(input, instructions, options)
        @client.post("/extract", payload)
      end

      def async(input:, instructions:, async: nil, **options)
        raise ArgumentError, "input is required" if input.nil?
        if instructions.nil? || (instructions.respond_to?(:empty?) && instructions.empty?)
          raise ArgumentError, "instructions are required"
        end

        payload = build_payload(input, instructions, options)
        payload[:async] = async unless async.nil?

        @client.post("/extract_async", payload)
      end

      private

      def build_payload(input, instructions, options)
        normalized_input = normalize_input(input)
        normalized_instructions = normalize_instructions(instructions)

        { input: normalized_input, instructions: normalized_instructions, **options }.compact
      end

      def normalize_input(input)
        return input unless input.is_a?(Hash)

        input[:url] || input["url"] || input
      end

      def normalize_instructions(instructions)
        return { schema: instructions } unless instructions.is_a?(Hash)
        return instructions if instructions.key?(:schema) || instructions.key?("schema")

        { schema: instructions }
      end
    end
  end
end

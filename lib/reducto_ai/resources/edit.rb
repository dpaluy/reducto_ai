# frozen_string_literal: true

module ReductoAI
  module Resources
    class Edit
      def initialize(client)
        @client = client
      end

      def sync(input:, instructions:, **options)
        raise ArgumentError, "input is required" if input.nil?
        if instructions.nil? || (instructions.respond_to?(:empty?) && instructions.empty?)
          raise ArgumentError, "instructions are required"
        end

        payload = build_payload(input, instructions, options)
        @client.post("/edit", payload)
      end

      def async(input:, instructions:, async: nil, **options)
        raise ArgumentError, "input is required" if input.nil?
        if instructions.nil? || (instructions.respond_to?(:empty?) && instructions.empty?)
          raise ArgumentError, "instructions are required"
        end

        payload = build_payload(input, instructions, options)
        payload[:async] = async unless async.nil?

        @client.post("/edit_async", payload)
      end

      private

      def build_payload(input, instructions, options)
        document_url = normalize_input(input)
        { document_url: document_url, edit_instructions: instructions, **options }.compact
      end

      def normalize_input(input)
        return input unless input.is_a?(Hash)

        input[:url] || input["url"] || input
      end
    end
  end
end

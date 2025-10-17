# frozen_string_literal: true

module ReductoAI
  module Actions
    class EditAsync
      def initialize(client: ReductoAI.client)
        @client = client
      end

      def call(document_url:, edit_instructions:, **options)
        validate!(document_url, edit_instructions)

        payload = {
          document_url:,
          edit_instructions: edit_instructions
        }

        payload.merge!(options.compact)

        client.post("/edit_async", payload)
      end

      private

      attr_reader :client

      def validate!(document_url, edit_instructions)
        raise ArgumentError, "document_url is required" if document_url.nil?
        raise ArgumentError, "edit_instructions are required" if blank?(edit_instructions)
      end

      def blank?(value)
        return true if value.nil?
        return value.empty? if value.respond_to?(:empty?)

        false
      end
    end
  end
end

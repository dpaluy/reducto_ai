# frozen_string_literal: true

module ReductoAI
  module Actions
    class Extract
      def initialize(client: ReductoAI.client)
        @client = client
      end

      def call(input:, instructions:, **options)
        validate!(input, instructions)

        client.post("/extract", { input:, instructions:, **options }.compact)
      end

      private

      attr_reader :client

      def validate!(input, instructions)
        raise ArgumentError, "input is required" if input.nil?
        raise ArgumentError, "instructions are required" if instructions.nil?
        return unless instructions.respond_to?(:empty?) && instructions.empty?

        raise ArgumentError, "instructions are required"
      end
    end
  end
end

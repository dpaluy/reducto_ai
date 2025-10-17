# frozen_string_literal: true

module ReductoAI
  module Actions
    class Parse
      def initialize(client: ReductoAI.client)
        @client = client
      end

      def call(input:, **options)
        raise ArgumentError, "input is required" if input.nil?

        client.post("/parse", { input:, **options }.compact)
      end

      private

      attr_reader :client
    end
  end
end

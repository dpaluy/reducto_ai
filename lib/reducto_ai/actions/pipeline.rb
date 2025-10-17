# frozen_string_literal: true

module ReductoAI
  module Actions
    class Pipeline
      def initialize(client: ReductoAI.client)
        @client = client
      end

      def call(input:, pipeline_id:, **options)
        validate!(input, pipeline_id)

        payload = { input:, pipeline_id: }
        payload.merge!(options.compact)

        client.post("/pipeline", payload)
      end

      private

      attr_reader :client

      def validate!(input, pipeline_id)
        raise ArgumentError, "input is required" if input.nil?
        raise ArgumentError, "pipeline_id is required" if pipeline_id.to_s.empty?
      end
    end
  end
end

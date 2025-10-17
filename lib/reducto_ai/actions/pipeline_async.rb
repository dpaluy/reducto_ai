# frozen_string_literal: true

module ReductoAI
  module Actions
    class PipelineAsync
      def initialize(client: ReductoAI.client)
        @client = client
      end

      def call(input:, pipeline_id:, async: nil, **options)
        validate!(input, pipeline_id)

        payload = {
          input:,
          pipeline_id: pipeline_id
        }
        payload[:async] = async unless async.nil?
        payload.merge!(options.compact)

        client.post("/pipeline_async", payload)
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

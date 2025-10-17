# frozen_string_literal: true

module ReductoAI
  module Resources
    class Pipeline
      def initialize(client)
        @client = client
      end

      def sync(input:, steps:, **options)
        raise ArgumentError, "input is required" if input.nil?
        raise ArgumentError, "steps are required" if steps.nil? || (steps.respond_to?(:empty?) && steps.empty?)

        payload = { input: input, steps: steps, **options }.compact
        @client.post("/pipeline", payload)
      end

      def async(input:, steps:, async: nil, **options)
        raise ArgumentError, "input is required" if input.nil?
        raise ArgumentError, "steps are required" if steps.nil? || (steps.respond_to?(:empty?) && steps.empty?)

        payload = { input: input, steps: steps }
        payload[:async] = async unless async.nil?
        payload.merge!(options.compact)

        @client.post("/pipeline_async", payload)
      end
    end
  end
end

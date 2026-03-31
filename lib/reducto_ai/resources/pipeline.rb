# frozen_string_literal: true

module ReductoAI
  module Resources
    # Pipeline resource for multi-step document processing workflows.
    #
    # Orchestrates multiple Reducto operations (parse, extract, split, edit)
    # in a single request, with outputs from earlier steps feeding into later ones.
    #
    # @example Parse then extract
    #   client = ReductoAI::Client.new
    #   result = client.pipeline.sync(
    #     input: "https://example.com/invoice.pdf",
    #     steps: [
    #       { type: "parse", output_formats: { markdown: true } },
    #       { type: "extract", instructions: { total: "number", date: "string" } }
    #     ]
    #   )
    #   extracted_data = result["result"]["steps"][1]["result"]
    #
    # @note Pipeline operations consume credits based on all steps executed.
    class Pipeline
      include AsyncPayload

      # @param client [Client] the Reducto API client
      # @api private
      def initialize(client)
        @client = client
      end

      # Executes a multi-step pipeline synchronously.
      #
      # @param input [String, Hash] Document URL or hash with :url key
      # @param steps [Array<Hash>] Array of step configurations. Each step
      #   must have a :type key ("parse", "extract", "split", "edit") and
      #   type-specific options.
      # @param options [Hash] Additional pipeline options
      #
      # @return [Hash] Pipeline results with keys:
      #   * "job_id" [String] - Job identifier
      #   * "status" [String] - Job status ("Completed")
      #   * "result" [Hash] - Contains "steps" array with each step's result
      #   * "usage" [Hash] - Credit usage details
      #
      # @raise [ArgumentError] if input or steps are nil/empty
      # @raise [ClientError] if step configuration is invalid
      # @raise [ServerError] if pipeline execution fails
      #
      # @example Parse and extract in one request
      #   result = client.pipeline.sync(
      #     input: "https://example.com/form.pdf",
      #     steps: [
      #       { type: "parse" },
      #       { type: "extract", instructions: { name: "string", amount: "number" } }
      #     ]
      #   )
      #
      # @see https://docs.reducto.ai/api-reference/pipeline Reducto Pipeline API
      def sync(input:, steps:, **options)
        raise ArgumentError, "input is required" if input.nil?
        raise ArgumentError, "steps are required" if steps.nil? || (steps.respond_to?(:empty?) && steps.empty?)

        payload = { input: input, steps: steps, **options }.compact
        @client.post("/pipeline", payload)
      end

      # Executes a multi-step pipeline asynchronously.
      #
      # Returns immediately with a job_id. Poll with {Jobs#retrieve} to get results.
      #
      # @param input [String, Hash] Document URL or hash with :url key
      # @param steps [Array<Hash>] Array of step configurations (same as {#sync})
      # @param async [Boolean, Hash, nil] Async options. `true` becomes an empty async payload,
      #   while a hash is sent as Reducto's nested `async` object.
      # @param options [Hash] Additional pipeline options
      #
      # @return [Hash] Job status with keys:
      #   * "job_id" [String] - Job identifier for polling
      #   * "status" [String] - Initial status ("Pending")
      #
      # @raise [ArgumentError] if input or steps are nil/empty
      #
      # @example
      #   job = client.pipeline.async(
      #     input: "https://example.com/complex-doc.pdf",
      #     steps: [
      #       { type: "split" },
      #       { type: "parse", output_formats: { markdown: true } }
      #     ]
      #   )
      #   job_id = job["job_id"]
      #
      # @see Jobs#retrieve
      # @see https://docs.reducto.ai/api-reference/pipeline-async
      def async(input:, steps:, async: nil, **options)
        raise ArgumentError, "input is required" if input.nil?
        raise ArgumentError, "steps are required" if steps.nil? || (steps.respond_to?(:empty?) && steps.empty?)

        payload = { input: input, steps: steps }
        apply_async_payload!(payload, async)
        payload.merge!(options.compact)

        @client.post("/pipeline_async", payload)
      end
    end
  end
end

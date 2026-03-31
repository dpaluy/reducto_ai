# frozen_string_literal: true

module ReductoAI
  module Resources
    # Extract resource for structured data extraction.
    #
    # Extracts specific information from documents based on a schema or instructions.
    # Returns structured JSON data matching the provided schema.
    #
    # @example Extract with schema
    #   client = ReductoAI::Client.new
    #   schema = {
    #     invoice_number: "string",
    #     total_amount: "number",
    #     line_items: ["object"]
    #   }
    #
    #   result = client.extract.sync(
    #     input: "https://example.com/invoice.pdf",
    #     instructions: schema
    #   )
    #   puts result["result"]
    #
    # @note Extraction operations consume credits based on document complexity
    #   and schema size.
    class Extract
      include AsyncPayload

      # @param client [Client] the Reducto API client
      # @api private
      def initialize(client)
        @client = client
      end

      # Extracts structured data from a document synchronously.
      #
      # @param input [String, Hash] Document URL or hash with :url key
      # @param instructions [Hash, String] Extraction schema or instructions.
      #   Can be a simple hash (auto-wrapped as `{ schema: ... }`) or
      #   a full instructions hash with a :schema key.
      # @param options [Hash] Additional extraction options
      #
      # @return [Hash] Extraction results with keys:
      #   * "job_id" [String] - Job identifier
      #   * "status" [String] - Job status ("Completed")
      #   * "result" [Hash] - Extracted data matching schema
      #   * "usage" [Hash] - Credit usage details
      #
      # @raise [ArgumentError] if input or instructions are nil/empty
      # @raise [ClientError] if schema is invalid
      # @raise [ServerError] if extraction fails
      #
      # @example Extract invoice data
      #   result = client.extract.sync(
      #     input: "https://example.com/invoice.pdf",
      #     instructions: {
      #       invoice_number: "string",
      #       total: "number"
      #     }
      #   )
      #
      # @see https://docs.reducto.ai/api-reference/extract Reducto Extract API
      def sync(input:, instructions:, **options)
        raise ArgumentError, "input is required" if input.nil?
        if instructions.nil? || (instructions.respond_to?(:empty?) && instructions.empty?)
          raise ArgumentError, "instructions are required"
        end

        payload = build_payload(input, instructions, options)
        @client.post("/extract", payload)
      end

      # Extracts structured data from a document asynchronously.
      #
      # Returns immediately with a job_id. Poll with {Jobs#retrieve} to get results.
      #
      # @param input [String, Hash] Document URL or hash with :url key
      # @param instructions [Hash, String] Extraction schema (same as {#sync})
      # @param async [Boolean, Hash, nil] Async options. `true` becomes an empty async payload,
      #   while a hash is sent as Reducto's nested `async` object.
      # @param options [Hash] Additional extraction options
      #
      # @return [Hash] Job status with keys:
      #   * "job_id" [String] - Job identifier for polling
      #   * "status" [String] - Initial status ("Pending")
      #
      # @raise [ArgumentError] if input or instructions are nil/empty
      #
      # @example Start async extraction
      #   job = client.extract.async(
      #     input: "https://example.com/contract.pdf",
      #     instructions: { parties: ["string"], terms: "string" }
      #   )
      #   job_id = job["job_id"]
      #
      # @see Jobs#retrieve
      # @see https://docs.reducto.ai/api-reference/extract-async
      def async(input:, instructions:, async: nil, **options)
        raise ArgumentError, "input is required" if input.nil?
        if instructions.nil? || (instructions.respond_to?(:empty?) && instructions.empty?)
          raise ArgumentError, "instructions are required"
        end

        payload = build_payload(input, instructions, options)
        apply_async_payload!(payload, async)

        @client.post("/extract_async", payload)
      end

      private

      # @private
      def build_payload(input, instructions, options)
        normalized_input = normalize_input(input)
        normalized_instructions = normalize_instructions(instructions)

        { input: normalized_input, instructions: normalized_instructions, **options }.compact
      end

      # @private
      def normalize_instructions(instructions)
        return { schema: instructions } unless instructions.is_a?(Hash)
        return instructions if instructions.key?(:schema) || instructions.key?("schema")

        { schema: instructions }
      end
    end
  end
end

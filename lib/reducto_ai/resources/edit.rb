# frozen_string_literal: true

module ReductoAI
  module Resources
    # Edit resource for PDF markup and annotation operations.
    #
    # Generates marked-up PDFs with highlights, annotations, or redactions
    # based on natural language instructions.
    #
    # @example Highlight key terms
    #   client = ReductoAI::Client.new
    #   result = client.edit.sync(
    #     input: "https://example.com/contract.pdf",
    #     instructions: "Highlight all mentions of payment terms and deadlines"
    #   )
    #   marked_pdf_url = result["result"]["document_url"]
    #
    # @note Edit operations consume credits based on document size and
    #   instruction complexity.
    class Edit
      # @param client [Client] the Reducto API client
      # @api private
      def initialize(client)
        @client = client
      end

      # Generates a marked-up PDF synchronously.
      #
      # @param input [String, Hash] Document URL or hash with :url key
      # @param instructions [String] Natural language editing instructions
      #   (e.g., "Highlight all dates", "Redact personal information")
      # @param options [Hash] Additional editing options
      #
      # @return [Hash] Edit results with keys:
      #   * "job_id" [String] - Job identifier
      #   * "status" [String] - Job status ("succeeded")
      #   * "result" [Hash] - Contains "document_url" with marked PDF
      #   * "usage" [Hash] - Credit usage details
      #
      # @raise [ArgumentError] if input or instructions are nil/empty
      # @raise [ClientError] if instructions are invalid
      # @raise [ServerError] if editing fails
      #
      # @example Redact sensitive info
      #   result = client.edit.sync(
      #     input: "https://example.com/report.pdf",
      #     instructions: "Redact all social security numbers"
      #   )
      #
      # @see https://docs.reducto.ai/api-reference/edit Reducto Edit API
      def sync(input:, instructions:, **options)
        raise ArgumentError, "input is required" if input.nil?
        if instructions.nil? || (instructions.respond_to?(:empty?) && instructions.empty?)
          raise ArgumentError, "instructions are required"
        end

        payload = build_payload(input, instructions, options)
        @client.post("/edit", payload)
      end

      # Generates a marked-up PDF asynchronously.
      #
      # Returns immediately with a job_id. Poll with {Jobs#retrieve} to get results.
      #
      # @param input [String, Hash] Document URL or hash with :url key
      # @param instructions [String] Natural language editing instructions
      # @param async [Boolean, nil] Async mode flag
      # @param options [Hash] Additional editing options
      #
      # @return [Hash] Job status with keys:
      #   * "job_id" [String] - Job identifier for polling
      #   * "status" [String] - Initial status ("processing")
      #
      # @raise [ArgumentError] if input or instructions are nil/empty
      #
      # @example
      #   job = client.edit.async(
      #     input: "https://example.com/legal-doc.pdf",
      #     instructions: "Highlight all liability clauses"
      #   )
      #   job_id = job["job_id"]
      #
      # @see Jobs#retrieve
      # @see https://docs.reducto.ai/api-reference/edit-async
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

      # @private
      def build_payload(input, instructions, options)
        document_url = normalize_input(input)
        { document_url: document_url, edit_instructions: instructions, **options }.compact
      end

      # @private
      def normalize_input(input)
        return input unless input.is_a?(Hash)

        input[:url] || input["url"] || input
      end
    end
  end
end

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
      include AsyncPayload

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
      #   * "status" [String] - Job status ("Completed")
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
      # @param async [Boolean, Hash, nil] Async options. `true` keeps the legacy no-options call,
      #   while a hash is translated to Reducto's current top-level edit async fields.
      #   `/edit_async` only accepts `priority` and `webhook`, not generic async metadata.
      # @param options [Hash] Additional editing options
      #
      # @return [Hash] Job status with keys:
      #   * "job_id" [String] - Job identifier for polling
      #   * "status" [String] - Initial status ("Pending")
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

        payload = build_payload(input, instructions, {})
        payload.merge!(translate_async_options(async))
        payload.merge!(options.compact)

        @client.post("/edit_async", payload)
      end

      private

      # @private
      def build_payload(input, instructions, options)
        document_url = normalize_input(input)
        { document_url: document_url, edit_instructions: instructions, **options }.compact
      end

      # Edit API uses top-level async keys (priority, webhook) rather than
      # the nested `async` object used by other resources. This mirrors the
      # Reducto API design where edit_async accepts these fields at root level.
      def translate_async_options(async)
        case async
        when nil, false, true
          {}
        when Hash
          normalized_async = async.each_with_object({}) do |(key, value), normalized|
            normalized[key.to_sym] = value
          end
          unsupported_keys = normalized_async.keys - %i[priority webhook]
          unless unsupported_keys.empty?
            raise ArgumentError, "unsupported async options: #{unsupported_keys.join(", ")}"
          end

          normalized_async.compact
        else
          raise ArgumentError, "async must be a Hash, true, false, or nil"
        end
      end
    end
  end
end

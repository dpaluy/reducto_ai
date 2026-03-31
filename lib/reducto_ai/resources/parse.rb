# frozen_string_literal: true

module ReductoAI
  # Resource classes for Reducto API endpoints.
  #
  # Each resource class corresponds to a set of related API operations
  # (Parse, Extract, Split, Edit, Pipeline, Jobs).
  module Resources
    # Parse resource for document parsing operations.
    #
    # Converts documents (PDFs, images, etc.) into structured formats like
    # Markdown, JSON, or HTML. Supports both synchronous and asynchronous modes.
    #
    # @example Synchronous parsing
    #   client = ReductoAI::Client.new
    #   result = client.parse.sync(
    #     input: "https://example.com/document.pdf",
    #     output_formats: { markdown: true }
    #   )
    #   puts result["result"]["markdown"]
    #
    # @example Asynchronous parsing
    #   job = client.parse.async(
    #     input: { url: "https://example.com/large-doc.pdf" },
    #     async: true
    #   )
    #   job_id = job["job_id"]
    #
    # @note Each parse operation consumes credits based on document complexity.
    #   See Reducto documentation for pricing details.
    class Parse
      include AsyncPayload

      # @param client [Client] the Reducto API client
      # @api private
      def initialize(client)
        @client = client
      end

      # Parses a document synchronously.
      #
      # Blocks until parsing completes and returns the full result.
      #
      # @param input [String, Hash] Document URL or hash with :url key
      # @param options [Hash] Additional parsing options
      # @option options [Hash] :output_formats Output format configuration
      #   (e.g., `{ markdown: true, html: true }`)
      # @option options [String] :mode Processing mode ("ocr", "auto")
      # @option options [Boolean] :use_cache Whether to use cached results
      #
      # @return [Hash] Parsed document with keys:
      #   * "job_id" [String] - Job identifier
      #   * "status" [String] - Job status ("Completed")
      #   * "result" [Hash] - Parsed content by format (e.g., "markdown", "html")
      #   * "usage" [Hash] - Credit usage details
      #
      # @raise [ArgumentError] if input is nil
      # @raise [ClientError] if document URL is invalid or inaccessible
      # @raise [ServerError] if parsing fails
      #
      # @example Parse to markdown
      #   result = client.parse.sync(
      #     input: "https://example.com/doc.pdf",
      #     output_formats: { markdown: true }
      #   )
      #
      # @see https://docs.reducto.ai/api-reference/parse Reducto Parse API
      def sync(input:, **options)
        raise ArgumentError, "input is required" if input.nil?

        normalized_input = normalize_input(input)
        payload = { input: normalized_input, **options }.compact
        @client.post("/parse", payload)
      end

      # Parses a document asynchronously.
      #
      # Returns immediately with a job_id. Poll with {Jobs#retrieve} to get results.
      #
      # @param input [String, Hash] Document URL or hash with :url key
      # @param async [Boolean, Hash, nil] Async options. `true` becomes an empty async payload,
      #   while a hash is sent as Reducto's nested `async` object.
      # @param options [Hash] Additional parsing options (same as {#sync})
      #
      # @return [Hash] Job status with keys:
      #   * "job_id" [String] - Job identifier for polling
      #   * "status" [String] - Initial status ("Pending")
      #
      # @raise [ArgumentError] if input is nil
      #
      # @example Start async parse and poll
      #   job = client.parse.async(input: "https://example.com/doc.pdf")
      #   job_id = job["job_id"]
      #
      #   # Poll for completion
      #   loop do
      #     status = client.jobs.retrieve(job_id: job_id)
      #     break if client.jobs.completed?(status)
      #     sleep 2
      #   end
      #
      # @see Jobs#retrieve
      # @see https://docs.reducto.ai/api-reference/async-parse Reducto Async Parse
      def async(input:, async: nil, **options)
        raise ArgumentError, "input is required" if input.nil?

        normalized_input = normalize_input(input)
        payload = { input: normalized_input }
        apply_async_payload!(payload, async)
        payload.merge!(options.compact)

        @client.post("/parse_async", payload)
      end
    end
  end
end

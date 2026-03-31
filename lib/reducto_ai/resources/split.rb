# frozen_string_literal: true

module ReductoAI
  module Resources
    # Split resource for document splitting operations.
    #
    # Divides documents into logical sections based on content structure,
    # returning page ranges and metadata for each section.
    #
    # @example Split document into sections
    #   client = ReductoAI::Client.new
    #   result = client.split.sync(
    #     input: "https://example.com/report.pdf"
    #   )
    #   result["result"]["sections"].each do |section|
    #     puts "#{section['title']}: pages #{section['start_page']}-#{section['end_page']}"
    #   end
    #
    # @note Split operations consume credits based on document size.
    class Split
      include AsyncPayload

      # @param client [Client] the Reducto API client
      # @api private
      def initialize(client)
        @client = client
      end

      # Splits a document into sections synchronously.
      #
      # @param input [String, Hash] Document URL or hash with :url key
      # @param options [Hash] Additional splitting options
      #
      # @return [Hash] Split results with keys:
      #   * "job_id" [String] - Job identifier
      #   * "status" [String] - Job status ("Completed")
      #   * "result" [Hash] - Sections with page ranges
      #   * "usage" [Hash] - Credit usage details
      #
      # @raise [ArgumentError] if input is nil
      # @raise [ClientError] if document URL is invalid
      # @raise [ServerError] if splitting fails
      #
      # @example
      #   result = client.split.sync(
      #     input: "https://example.com/document.pdf"
      #   )
      #
      # @see https://docs.reducto.ai/api-reference/split Reducto Split API
      def sync(input:, **options)
        raise ArgumentError, "input is required" if input.nil?

        normalized_input = normalize_input(input)
        payload = { input: normalized_input, **options }.compact
        @client.post("/split", payload)
      end

      # Splits a document into sections asynchronously.
      #
      # Returns immediately with a job_id. Poll with {Jobs#retrieve} to get results.
      #
      # @param input [String, Hash] Document URL or hash with :url key
      # @param async [Boolean, Hash, nil] Async options. `true` becomes an empty async payload,
      #   while a hash is sent as Reducto's nested `async` object.
      # @param options [Hash] Additional splitting options
      #
      # @return [Hash] Job status with keys:
      #   * "job_id" [String] - Job identifier for polling
      #   * "status" [String] - Initial status ("Pending")
      #
      # @raise [ArgumentError] if input is nil
      #
      # @example
      #   job = client.split.async(
      #     input: "https://example.com/book.pdf"
      #   )
      #   job_id = job["job_id"]
      #
      # @see Jobs#retrieve
      # @see https://docs.reducto.ai/api-reference/split-async
      def async(input:, async: nil, **options)
        raise ArgumentError, "input is required" if input.nil?

        normalized_input = normalize_input(input)
        payload = { input: normalized_input }
        apply_async_payload!(payload, async)
        payload.merge!(options.compact)

        @client.post("/split_async", payload)
      end
    end
  end
end

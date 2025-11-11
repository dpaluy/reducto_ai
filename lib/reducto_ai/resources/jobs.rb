# frozen_string_literal: true

module ReductoAI
  module Resources
    # Jobs resource for job management and file upload operations.
    #
    # Provides methods to list, retrieve, cancel jobs, upload files,
    # and configure webhooks for async job notifications.
    #
    # @example Poll for job completion
    #   client = ReductoAI::Client.new
    #   job = client.parse.async(input: "https://example.com/doc.pdf")
    #
    #   loop do
    #     status = client.jobs.retrieve(job_id: job["job_id"])
    #     break if status["status"] == "succeeded"
    #     sleep 2
    #   end
    #   result = status["result"]
    #
    # @example Upload a local file
    #   upload_result = client.jobs.upload(file: "/path/to/document.pdf")
    #   document_url = upload_result["url"]
    #   client.parse.sync(input: document_url)
    class Jobs
      # @param client [Client] the Reducto API client
      # @api private
      def initialize(client)
        @client = client
      end

      # Returns API version information.
      #
      # @return [Hash] Version details
      #
      # @example
      #   version_info = client.jobs.version
      #   puts version_info["version"]
      def version
        @client.request(:get, "/version")
      end

      # Lists jobs with optional filtering.
      #
      # @param options [Hash] Query parameters for filtering
      # @option options [String] :status Filter by job status ("processing", "succeeded", "failed")
      # @option options [Integer] :limit Maximum number of jobs to return
      # @option options [Integer] :offset Pagination offset
      #
      # @return [Hash] Job list with pagination metadata
      #
      # @example List recent jobs
      #   jobs = client.jobs.list(limit: 10)
      #   jobs["jobs"].each { |job| puts job["job_id"] }
      #
      # @example Filter by status
      #   failed_jobs = client.jobs.list(status: "failed")
      #
      # @see https://docs.reducto.ai/api-reference/jobs
      def list(**options)
        params = options.compact
        @client.request(:get, "/jobs", params: params)
      end

      # Cancels a running async job.
      #
      # @param job_id [String] Job identifier to cancel
      #
      # @return [Hash] Cancellation result
      #
      # @raise [ArgumentError] if job_id is nil or empty
      # @raise [ClientError] if job doesn't exist or is not cancellable
      #
      # @example
      #   client.jobs.cancel(job_id: "job_abc123")
      #
      # @see https://docs.reducto.ai/api-reference/cancel
      def cancel(job_id:)
        raise ArgumentError, "job_id is required" if job_id.nil? || job_id.to_s.strip.empty?

        @client.request(:post, "/cancel/#{job_id}")
      end

      # Retrieves job status and results.
      #
      # Used to poll async jobs until completion. Completed jobs include
      # full results in the response.
      #
      # @param job_id [String] Job identifier to retrieve
      #
      # @return [Hash] Job status with keys:
      #   * "job_id" [String] - Job identifier
      #   * "status" [String] - Current status ("processing", "succeeded", "failed")
      #   * "result" [Hash] - Results (only present when status is "succeeded")
      #   * "error" [String] - Error message (only present when status is "failed")
      #
      # @raise [ArgumentError] if job_id is nil or empty
      # @raise [ClientError] if job doesn't exist
      #
      # @example Poll until complete
      #   loop do
      #     status = client.jobs.retrieve(job_id: job_id)
      #     break if %w[succeeded failed].include?(status["status"])
      #     sleep 2
      #   end
      #
      # @see https://docs.reducto.ai/api-reference/job
      def retrieve(job_id:)
        raise ArgumentError, "job_id is required" if job_id.nil? || job_id.to_s.strip.empty?

        @client.request(:get, "/job/#{job_id}")
      end

      # Uploads a local file to Reducto's storage.
      #
      # Returns a URL that can be used as input for other API operations.
      # Useful when processing local files instead of publicly accessible URLs.
      #
      # @param file [String, File, IO] File path or file-like object to upload
      # @param extension [String, nil] File extension override (e.g., "pdf", "png")
      #
      # @return [Hash] Upload result with keys:
      #   * "url" [String] - Uploaded file URL for use in API calls
      #   * "job_id" [String] - Upload job identifier
      #
      # @raise [ArgumentError] if file is nil or path doesn't exist
      # @raise [ServerError] if upload fails
      #
      # @example Upload local PDF
      #   upload = client.jobs.upload(file: "/path/to/invoice.pdf")
      #   result = client.parse.sync(input: upload["url"])
      #
      # @example Upload with File object
      #   File.open("/path/to/doc.pdf", "rb") do |f|
      #     upload = client.jobs.upload(file: f, extension: "pdf")
      #   end
      #
      # @see https://docs.reducto.ai/api-reference/upload
      def upload(file:, extension: nil)
        raise ArgumentError, "file is required" if file.nil?

        upload_io = build_upload_io(file)
        body = { file: upload_io }
        params = {}
        params[:extension] = extension unless extension.nil?

        @client.request(:post, "/upload", body: body, params: params)
      end

      # Configures webhook notifications for async jobs.
      #
      # @return [Hash] Webhook configuration result
      #
      # @example
      #   client.jobs.configure_webhook
      #
      # @see https://docs.reducto.ai/api-reference/configure-webhook
      def configure_webhook
        @client.request(:post, "/configure_webhook")
      end

      private

      # @private
      def build_upload_io(file)
        if file.is_a?(String)
          raise ArgumentError, "file path does not exist" unless File.exist?(file)

          filename = File.basename(file)
        else
          filename = if file.respond_to?(:path) && file.path
                       File.basename(file.path)
                     else
                       "upload"
                     end

        end
        Faraday::UploadIO.new(file, "application/octet-stream", filename)
      end
    end
  end
end

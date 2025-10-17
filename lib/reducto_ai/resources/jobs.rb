# frozen_string_literal: true

module ReductoAI
  module Resources
    class Jobs
      def initialize(client)
        @client = client
      end

      def version
        @client.request(:get, "/version")
      end

      def list(**options)
        params = options.compact
        @client.request(:get, "/jobs", params: params)
      end

      def cancel(job_id:)
        raise ArgumentError, "job_id is required" if job_id.nil? || job_id.to_s.strip.empty?

        @client.request(:post, "/cancel/#{job_id}")
      end

      def retrieve(job_id:)
        raise ArgumentError, "job_id is required" if job_id.nil? || job_id.to_s.strip.empty?

        @client.request(:get, "/job/#{job_id}")
      end

      def upload(file:, extension: nil)
        raise ArgumentError, "file is required" if file.nil?

        upload_io = build_upload_io(file)
        body = { file: upload_io }
        params = {}
        params[:extension] = extension unless extension.nil?

        @client.request(:post, "/upload", body: body, params: params)
      end

      def configure_webhook
        @client.request(:post, "/configure_webhook")
      end

      private

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

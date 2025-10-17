# frozen_string_literal: true

require "faraday/multipart"

module ReductoAI
  module Actions
    class Upload
      def initialize(client: ReductoAI.client)
        @client = client
      end

      # file: String path or IO
      # extension: optional query param (e.g., "pdf")
      def call(file:, extension: nil)
        raise ArgumentError, "file is required" if file.nil?

        upload_io = build_upload_io(file)
        body = { file: upload_io }
        params = {}
        params[:extension] = extension unless extension.nil?

        client.request(:post, "/upload", body: body, params: params)
      end

      private

      attr_reader :client

      def build_upload_io(file)
        if file.is_a?(String)
          path = file
          raise ArgumentError, "file path does not exist" unless File.exist?(path)
          Faraday::UploadIO.new(path, "application/octet-stream", File.basename(path))
        else
          io = file
          filename = io.respond_to?(:path) ? File.basename(io.path) : "upload.bin"
          Faraday::UploadIO.new(io, "application/octet-stream", filename)
        end
      end
    end
  end
end

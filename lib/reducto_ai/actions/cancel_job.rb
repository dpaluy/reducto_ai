# frozen_string_literal: true

module ReductoAI
  module Actions
    class CancelJob
      def initialize(client: ReductoAI.client)
        @client = client
      end

      def call(job_id:)
        validate!(job_id)
        client.request(:post, "/cancel/#{job_id}")
      end

      private

      attr_reader :client

      def validate!(job_id)
        raise ArgumentError, "job_id is required" if job_id.to_s.empty?
      end
    end
  end
end

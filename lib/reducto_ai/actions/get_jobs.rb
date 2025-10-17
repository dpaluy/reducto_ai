# frozen_string_literal: true

module ReductoAI
  module Actions
    class GetJobs
      MIN_LIMIT = 1
      MAX_LIMIT = 500

      def initialize(client: ReductoAI.client)
        @client = client
      end

      def call(exclude_configs: nil, cursor: nil, limit: nil)
        params = build_params(exclude_configs:, cursor:, limit:)

        client.request(:get, "/jobs", params: params)
      end

      private

      attr_reader :client

      def build_params(exclude_configs:, cursor:, limit:)
        params = {}
        params[:exclude_configs] = exclude_configs unless exclude_configs.nil?
        params[:cursor] = cursor unless cursor.nil?
        params[:limit] = validate_limit(limit) unless limit.nil?

        return if params.empty?

        params
      end

      def validate_limit(limit)
        raise ArgumentError, "limit must be an Integer" unless limit.is_a?(Integer)

        unless (MIN_LIMIT..MAX_LIMIT).cover?(limit)
          raise ArgumentError,
                "limit must be between #{MIN_LIMIT} and #{MAX_LIMIT}"
        end

        limit
      end
    end
  end
end

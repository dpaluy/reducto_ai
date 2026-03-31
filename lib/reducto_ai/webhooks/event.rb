# frozen_string_literal: true

require "json"

module ReductoAI
  module Webhooks
    class Event
      attr_reader :payload, :headers

      def self.parse(payload, headers: {})
        parsed_payload = payload.is_a?(String) ? JSON.parse(payload) : payload
        new(parsed_payload, headers: headers)
      end

      def initialize(payload, headers: {})
        @payload = stringify_keys(payload || {})
        @headers = stringify_keys(headers || {})
      end

      def svix_id
        headers["svix-id"] || headers["webhook-id"]
      end

      def job_id
        payload["job_id"]
      end

      def status
        payload["status"]
      end

      def metadata
        payload["metadata"] || {}
      end

      def normalized_status
        ReductoAI::JobStatus.normalize_status(status)
      end

      def completed?
        ReductoAI::JobStatus.completed?(status)
      end

      def failed?
        ReductoAI::JobStatus.failed?(status)
      end

      def to_h
        payload
      end

      private

      def stringify_keys(value)
        case value
        when Hash
          value.each_with_object({}) do |(key, child_value), normalized|
            normalized[key.to_s] = stringify_keys(child_value)
          end
        when Array
          value.map { |child_value| stringify_keys(child_value) }
        else
          value
        end
      end
    end
  end
end

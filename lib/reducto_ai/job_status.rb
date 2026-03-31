# frozen_string_literal: true

module ReductoAI
  module JobStatus
    extend self

    STATUS_MAP = {
      "pending" => "Pending",
      "idle" => "Pending",
      "inprogress" => "InProgress",
      "processing" => "InProgress",
      "running" => "InProgress",
      "completing" => "Completing",
      "completed" => "Completed",
      "complete" => "Completed",
      "succeeded" => "Completed",
      "failed" => "Failed"
    }.freeze

    def normalize_status(value_or_response)
      raw_status = extract_status(value_or_response)
      return nil if raw_status.nil?

      STATUS_MAP.fetch(raw_status.to_s.downcase, raw_status.to_s)
    end

    def pending?(value_or_response)
      normalize_status(value_or_response) == "Pending"
    end

    def in_progress?(value_or_response)
      normalize_status(value_or_response) == "InProgress"
    end

    def completing?(value_or_response)
      normalize_status(value_or_response) == "Completing"
    end

    def completed?(value_or_response)
      normalize_status(value_or_response) == "Completed"
    end

    def failed?(value_or_response)
      normalize_status(value_or_response) == "Failed"
    end

    def terminal?(value_or_response)
      completed?(value_or_response) || failed?(value_or_response)
    end

    private

    def extract_status(value_or_response)
      case value_or_response
      when Hash
        value_or_response["status"] || value_or_response[:status]
      else
        if value_or_response.respond_to?(:status)
          value_or_response.status
        else
          value_or_response
        end
      end
    end
  end
end

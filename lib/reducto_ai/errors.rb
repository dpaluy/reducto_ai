# frozen_string_literal: true

module ReductoAI
  # Base error class for all Reducto API errors.
  #
  # All API-related exceptions inherit from this class and include
  # HTTP status code and response body for debugging.
  #
  # @example Handling errors
  #   begin
  #     client.parse.sync(input: "invalid-url")
  #   rescue ReductoAI::AuthenticationError => e
  #     puts "Auth failed: #{e.message}"
  #   rescue ReductoAI::ClientError => e
  #     puts "Client error (#{e.status}): #{e.body}"
  #   rescue ReductoAI::Error => e
  #     puts "API error: #{e.message}"
  #   end
  class Error < StandardError
    # @return [Integer, nil] HTTP status code
    attr_reader :status

    # @return [Hash, String, nil] Response body
    attr_reader :body

    # Creates a new error instance.
    #
    # @param message [String, nil] Error message
    # @param status [Integer, nil] HTTP status code
    # @param body [Hash, String, nil] Response body
    def initialize(message = nil, status: nil, body: nil)
      super(message)
      @status = status
      @body = body
    end
  end

  # Raised on 401 Unauthorized responses.
  #
  # Indicates invalid or missing API key.
  #
  # @example
  #   # Raised when API key is invalid
  #   client = ReductoAI::Client.new(api_key: "invalid-key")
  #   client.parse.sync(input: "https://example.com/doc.pdf")
  #   # => ReductoAI::AuthenticationError: Unauthorized (401): check API key
  class AuthenticationError < Error; end

  # Raised on 4xx client errors (400, 404, 422).
  #
  # Indicates invalid request parameters, missing resources, or
  # validation failures.
  #
  # @example
  #   # Raised when input is invalid
  #   client.parse.sync(input: "not-a-valid-url")
  #   # => ReductoAI::ClientError: HTTP 400: Invalid input URL
  class ClientError < Error; end

  # Raised on 429 Too Many Requests responses.
  #
  # Indicates API rate limit has been exceeded. Consumers should implement
  # retry logic with backoff.
  class RateLimitError < ClientError; end

  # Raised on 5xx server errors.
  #
  # Indicates Reducto API internal errors or temporary failures.
  #
  # @example
  #   # Raised on API server issues
  #   client.parse.sync(input: "https://example.com/doc.pdf")
  #   # => ReductoAI::ServerError: HTTP 500: Internal server error
  class ServerError < Error; end

  # Raised on network connection or timeout failures.
  #
  # Indicates network issues, DNS failures, or timeout exceeded.
  #
  # @example
  #   # Raised when request times out
  #   client = ReductoAI::Client.new(read_timeout: 1)
  #   client.parse.sync(input: "https://example.com/large-doc.pdf")
  #   # => ReductoAI::NetworkError: Network error: execution expired
  class NetworkError < Error; end

  # Raised when waiting for an async job exceeds the configured timeout or attempt limit.
  class JobTimeoutError < Error; end

  # Raised when an async job reaches a failed terminal state.
  class JobFailedError < Error; end

  # Raised when webhook signature verification fails.
  class WebhookVerificationError < Error; end
end

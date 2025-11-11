# frozen_string_literal: true

require "logger"

module ReductoAI
  # Configuration class for the ReductoAI client.
  #
  # Manages API credentials, timeouts, logging, and exception handling behavior.
  # Configuration can be set via environment variables or through the global
  # {ReductoAI.configure} method.
  #
  # @example Environment-based configuration
  #   # Set these environment variables:
  #   # REDUCTO_API_KEY=your-api-key
  #   # REDUCTO_BASE_URL=https://platform.reducto.ai
  #   # REDUCTO_OPEN_TIMEOUT=10
  #   # REDUCTO_READ_TIMEOUT=60
  #
  #   config = ReductoAI::Config.new
  #   config.api_key # => "your-api-key"
  #
  # @example Explicit configuration
  #   ReductoAI.configure do |config|
  #     config.api_key = "your-api-key"
  #     config.logger = Rails.logger
  #     config.open_timeout = 10
  #   end
  class Config
    # @return [String, nil] Reducto API key (from REDUCTO_API_KEY env var)
    attr_accessor :api_key

    # @return [String] Base URL for Reducto API (default: https://platform.reducto.ai)
    attr_accessor :base_url

    # @return [Integer] Connection open timeout in seconds (default: 5)
    attr_accessor :open_timeout

    # @return [Integer] Request read timeout in seconds (default: 30)
    attr_accessor :read_timeout

    # @return [Boolean] Whether to raise exceptions on API errors (default: true)
    attr_accessor :raise_exceptions

    # @return [Logger] Logger instance for debugging
    attr_writer :logger

    # Creates a new configuration instance with defaults from environment variables.
    def initialize
      @api_key = ENV.fetch("REDUCTO_API_KEY", nil)
      @base_url = ENV.fetch("REDUCTO_BASE_URL", "https://platform.reducto.ai")
      @open_timeout = integer_or_default("REDUCTO_OPEN_TIMEOUT", 5)
      @read_timeout = integer_or_default("REDUCTO_READ_TIMEOUT", 30)
      @raise_exceptions = true
    end

    # Returns the logger instance.
    #
    # Defaults to `Rails.logger` if Rails is available, otherwise a stderr Logger.
    #
    # @return [Logger] the logger instance
    def logger
      @logger ||= (defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger) || Logger.new($stderr)
    end

    private

    # @private
    def integer_or_default(key, default)
      Integer(ENV.fetch(key, default))
    rescue StandardError
      default
    end
  end
end

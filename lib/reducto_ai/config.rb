# frozen_string_literal: true

require "logger"

module ReductoAI
  class Config
    attr_accessor :api_key, :base_url, :open_timeout, :read_timeout, :raise_exceptions
    attr_writer :logger

    def initialize
      @api_key = ENV.fetch("REDUCTO_API_KEY", nil)
      @base_url = ENV.fetch("REDUCTO_BASE_URL", "https://platform.reducto.ai")
      @open_timeout = integer_or_default("REDUCTO_OPEN_TIMEOUT", 5)
      @read_timeout = integer_or_default("REDUCTO_READ_TIMEOUT", 30)
      @raise_exceptions = true
    end

    def logger
      @logger ||= (defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger) || Logger.new($stderr)
    end

    private

    def integer_or_default(key, default)
      Integer(ENV.fetch(key, default))
    rescue StandardError
      default
    end
  end
end

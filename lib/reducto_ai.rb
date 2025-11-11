# frozen_string_literal: true

require_relative "reducto_ai/version"
require_relative "reducto_ai/config"
require_relative "reducto_ai/errors"
require_relative "reducto_ai/client"
require_relative "reducto_ai/engine"

# Main namespace for the ReductoAI gem.
#
# Provides global configuration management for the Reducto API client.
# Use {.configure} to set API credentials and options, then create a {Client}
# instance to interact with the Reducto document intelligence API.
#
# @example Basic configuration
#   ReductoAI.configure do |config|
#     config.api_key = ENV.fetch("REDUCTO_API_KEY")
#     config.base_url = "https://platform.reducto.ai"
#   end
#
#   client = ReductoAI::Client.new
#   result = client.parse.sync(input: "https://example.com/document.pdf")
#
# @see Client
# @see Config
module ReductoAI
  class << self
    # Returns the global configuration instance.
    #
    # @return [Config] the current configuration object
    def config
      @config ||= Config.new
    end

    # Configures the ReductoAI client globally.
    #
    # @example Set API key and timeouts
    #   ReductoAI.configure do |config|
    #     config.api_key = "your-api-key"
    #     config.open_timeout = 10
    #     config.read_timeout = 60
    #   end
    #
    # @yield [config] Gives the configuration object to the block
    # @yieldparam config [Config] the configuration instance to modify
    # @return [void]
    def configure
      yield(config)
    end

    # Resets the global configuration to nil.
    #
    # Primarily used for testing to ensure a clean configuration state.
    #
    # @return [void]
    def reset_configuration!
      @config = nil
    end
  end
end

# Provide a compatibility alias without requiring Rails inflector acronym config
ReductoAi = ReductoAI unless defined?(ReductoAi)

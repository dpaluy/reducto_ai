# frozen_string_literal: true

require_relative "reducto_ai/version"
require_relative "reducto_ai/config"
require_relative "reducto_ai/errors"
require_relative "reducto_ai/client"
require_relative "reducto_ai/engine"

module ReductoAI
  class << self
    def config
      @config ||= Config.new
    end

    def configure
      yield(config)
    end

    def reset_configuration!
      @config = nil
    end
  end
end

# Provide a compatibility alias without requiring Rails inflector acronym config
ReductoAi = ReductoAI unless defined?(ReductoAi)

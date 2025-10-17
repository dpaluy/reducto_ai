# frozen_string_literal: true

require_relative "reducto_ai/version"
require_relative "reducto_ai/config"
require_relative "reducto_ai/errors"
require_relative "reducto_ai/client"
require_relative "reducto_ai/engine"
require_relative "reducto_ai/actions/parse"
require_relative "reducto_ai/actions/parse_async"
require_relative "reducto_ai/actions/split"
require_relative "reducto_ai/actions/split_async"
require_relative "reducto_ai/actions/extract"
require_relative "reducto_ai/actions/extract_async"
require_relative "reducto_ai/actions/edit"
require_relative "reducto_ai/actions/edit_async"
require_relative "reducto_ai/actions/pipeline"
require_relative "reducto_ai/actions/pipeline_async"
require_relative "reducto_ai/actions/get_version"
require_relative "reducto_ai/actions/get_jobs"
require_relative "reducto_ai/actions/cancel_job"
require_relative "reducto_ai/actions/retrieve_parse"
require_relative "reducto_ai/actions/upload"
require_relative "reducto_ai/actions/configure_webhook"

module ReductoAI
  class << self
    def config
      @config ||= Config.new
    end

    def configure
      yield(config)
      @client = nil
    end

    def reset_configuration!
      @config = nil
    end

    def client
      @client ||= Client.new
    end

    attr_writer :client

    def parse(...)
      Actions::Parse.new(client: client).call(...)
    end

    def parse_async(...)
      Actions::ParseAsync.new(client: client).call(...)
    end

    def split(...)
      Actions::Split.new(client: client).call(...)
    end

    def split_async(...)
      Actions::SplitAsync.new(client: client).call(...)
    end

    def extract(...)
      Actions::Extract.new(client: client).call(...)
    end

    def extract_async(...)
      Actions::ExtractAsync.new(client: client).call(...)
    end

    def edit(...)
      Actions::Edit.new(client: client).call(...)
    end

    def edit_async(...)
      Actions::EditAsync.new(client: client).call(...)
    end

    def pipeline(...)
      Actions::Pipeline.new(client: client).call(...)
    end

    def pipeline_async(...)
      Actions::PipelineAsync.new(client: client).call(...)
    end

    def version
      Actions::GetVersion.new(client: client).call
    end

    def jobs(...)
      Actions::GetJobs.new(client: client).call(...)
    end

    def cancel_job(...)
      Actions::CancelJob.new(client: client).call(...)
    end

    def retrieve_parse(...)
      Actions::RetrieveParse.new(client: client).call(...)
    end

    def upload(...)
      Actions::Upload.new(client: client).call(...)
    end

    def configure_webhook
      Actions::ConfigureWebhook.new(client: client).call
    end
  end
end

# Provide a compatibility alias without requiring Rails inflector acronym config
ReductoAi = ReductoAI unless defined?(ReductoAi)

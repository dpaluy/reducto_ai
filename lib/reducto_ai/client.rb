# frozen_string_literal: true

require "faraday"
require "json"
require "faraday/multipart"
require_relative "resources/async_payload"
require_relative "resources/parse"
require_relative "resources/extract"
require_relative "resources/split"
require_relative "resources/edit"
require_relative "resources/pipeline"
require_relative "resources/jobs"

module ReductoAI
  # HTTP client for the Reducto document intelligence API.
  #
  # Provides access to all Reducto API endpoints through resource objects.
  # Configure globally via {ReductoAI.configure} or pass parameters directly
  # to the constructor.
  #
  # @example Using global configuration
  #   ReductoAI.configure do |config|
  #     config.api_key = ENV["REDUCTO_API_KEY"]
  #   end
  #
  #   client = ReductoAI::Client.new
  #   client.parse.sync(input: "https://example.com/doc.pdf")
  #
  # @example Using per-instance configuration
  #   client = ReductoAI::Client.new(
  #     api_key: "your-key",
  #     read_timeout: 60
  #   )
  #
  # @see Resources::Parse
  # @see Resources::Extract
  # @see Resources::Split
  # @see Resources::Edit
  # @see Resources::Pipeline
  # @see Resources::Jobs
  class Client
    # @return [String] Reducto API key
    attr_reader :api_key

    # @return [String] Base URL for API requests
    attr_reader :base_url

    # @return [Logger] Logger instance for debugging
    attr_reader :logger

    # @return [Integer] Connection open timeout in seconds
    attr_reader :open_timeout

    # @return [Integer] Request read timeout in seconds
    attr_reader :read_timeout

    # Creates a new Reducto API client.
    #
    # @param api_key [String, nil] Reducto API key (defaults to global config)
    # @param base_url [String, nil] API base URL (defaults to global config)
    # @param logger [Logger, nil] Logger instance (defaults to global config)
    # @param open_timeout [Integer, nil] Connection timeout in seconds (defaults to global config)
    # @param read_timeout [Integer, nil] Read timeout in seconds (defaults to global config)
    #
    # @raise [ArgumentError] if api_key is missing or empty
    #
    # @example
    #   client = ReductoAI::Client.new(api_key: "sk-...")
    def initialize(api_key: nil, base_url: nil, logger: nil, open_timeout: nil, read_timeout: nil)
      configuration = ReductoAI.config

      @api_key = api_key || configuration.api_key
      @base_url = base_url || configuration.base_url
      @logger = logger || configuration.logger
      @open_timeout = open_timeout || configuration.open_timeout
      @read_timeout = read_timeout || configuration.read_timeout

      raise ArgumentError, "Missing API key for ReductoAI" if @api_key.to_s.empty?
    end

    # Returns the Parse resource for document parsing operations.
    #
    # @return [Resources::Parse] parse operations interface
    # @see Resources::Parse
    def parse
      @parse ||= Resources::Parse.new(self)
    end

    # Returns the Extract resource for structured data extraction.
    #
    # @return [Resources::Extract] extract operations interface
    # @see Resources::Extract
    def extract
      @extract ||= Resources::Extract.new(self)
    end

    # Returns the Split resource for document splitting operations.
    #
    # @return [Resources::Split] split operations interface
    # @see Resources::Split
    def split
      @split ||= Resources::Split.new(self)
    end

    # Returns the Edit resource for PDF markup operations.
    #
    # @return [Resources::Edit] edit operations interface
    # @see Resources::Edit
    def edit
      @edit ||= Resources::Edit.new(self)
    end

    # Returns the Pipeline resource for multi-step workflows.
    #
    # @return [Resources::Pipeline] pipeline operations interface
    # @see Resources::Pipeline
    def pipeline
      @pipeline ||= Resources::Pipeline.new(self)
    end

    # Returns the Jobs resource for job management operations.
    #
    # @return [Resources::Jobs] jobs operations interface
    # @see Resources::Jobs
    def jobs
      @jobs ||= Resources::Jobs.new(self)
    end

    # Makes an HTTP request to the Reducto API.
    #
    # @param method [Symbol] HTTP method (:get, :post, :put, :delete)
    # @param path [String] API endpoint path
    # @param body [Hash, nil] request body
    # @param params [Hash, nil] query parameters
    #
    # @return [Hash] parsed JSON response
    # @raise [AuthenticationError] on 401 responses
    # @raise [ClientError] on 4xx responses
    # @raise [ServerError] on 5xx responses
    # @raise [NetworkError] on connection/timeout failures
    #
    # @api private
    def request(method, path, body: nil, params: nil)
      response = execute_request(method, path, body: body, params: params)
      log_response(method, path, response)
      handle_response(response)
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
      raise NetworkError, "Network error: #{e.message}"
    end

    # Convenience method for POST requests.
    #
    # @param path [String] API endpoint path
    # @param body [Hash] request body
    # @return [Hash] parsed JSON response
    #
    # @api private
    def post(path, body)
      request(:post, path, body: body)
    end

    private

    def connection
      @connection ||= Faraday.new(url: base_url) do |faraday|
        faraday.options.timeout = read_timeout
        faraday.options.open_timeout = open_timeout
        faraday.request :multipart
        faraday.adapter Faraday.default_adapter
      end
    end

    def handle_response(response)
      status = response.status
      body = response.body
      return coerce_body(body) if success?(status)

      parsed_body = parse_error_body(body)
      return handle_auth_error(parsed_body, status) if status == 401
      return handle_rate_limit_error(parsed_body, status) if status == 429
      return handle_client_error(parsed_body, status) if client_error?(status)
      return handle_server_error(parsed_body, status) if server_error?(status)

      raise Error.new(error_message(status, parsed_body), status: status, body: parsed_body)
    end

    def coerce_body(body)
      return {} if body.nil? || body.empty?
      return body unless body.is_a?(String)

      JSON.parse(body)
    end

    def parse_error_body(body)
      return body if body.is_a?(Hash)
      return body if body.nil? || body.empty?

      JSON.parse(body)
    rescue JSON::ParserError
      body
    end

    def error_message(status, body)
      detail = body.is_a?(Hash) ? (body["error"] || body["message"] || body.to_json) : body.to_s
      "HTTP #{status}: #{detail}"
    end

    def log_response(method, path, response)
      return unless logger

      logger.debug("ReductoAI #{method.to_s.upcase} #{path} -> #{response.status}")
    end

    def success?(status)
      (200..299).cover?(status)
    end

    def client_error?(status)
      [400, 403, 404, 422].include?(status)
    end

    def server_error?(status)
      (500..599).cover?(status)
    end

    def handle_auth_error(body, status)
      raise AuthenticationError.new("Unauthorized (401): check API key", status: status, body: body)
    end

    def handle_rate_limit_error(body, status)
      raise RateLimitError.new(error_message(status, body), status: status, body: body)
    end

    def handle_client_error(body, status)
      raise ClientError.new(error_message(status, body), status: status, body: body)
    end

    def handle_server_error(body, status)
      raise ServerError.new(error_message(status, body), status: status, body: body)
    end

    def execute_request(method, path, body:, params:)
      connection.public_send(method, path) do |req|
        apply_headers(req)
        apply_body(req, body) if body
        req.params.update(params) if params
      end
    end

    def apply_headers(request)
      request.headers["Authorization"] = "Bearer #{api_key}"
      request.headers["Accept"] = "application/json"
    end

    def apply_body(request, body)
      if multipart_body?(body)
        request.body = body
      else
        request.headers["Content-Type"] = "application/json"
        request.body = JSON.generate(body)
      end
    end

    def multipart_body?(body)
      return false unless body
      return true if file_part?(body)

      body.is_a?(Hash) && body.values.any? { |v| file_part?(v) }
    end

    def file_part?(value)
      (defined?(Faraday::UploadIO) && value.is_a?(Faraday::UploadIO)) ||
        (defined?(Faraday::Multipart::FilePart) && value.is_a?(Faraday::Multipart::FilePart))
    end
  end
end

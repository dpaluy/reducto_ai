# frozen_string_literal: true

require "faraday"
require "json"
require "faraday/multipart"

module ReductoAI
  class Client
    attr_reader :api_key, :base_url, :logger, :open_timeout, :read_timeout

    def initialize(api_key: nil, base_url: nil, logger: nil, open_timeout: nil, read_timeout: nil)
      configuration = ReductoAI.config

      @api_key = api_key || configuration.api_key
      @base_url = base_url || configuration.base_url
      @logger = logger || configuration.logger
      @open_timeout = open_timeout || configuration.open_timeout
      @read_timeout = read_timeout || configuration.read_timeout

      raise ArgumentError, "Missing API key for ReductoAI" if @api_key.to_s.empty?
    end

    def request(method, path, body: nil, params: nil)
      response = execute_request(method, path, body: body, params: params)
      log_response(method, path, response)
      handle_response(response)
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
      raise NetworkError, "Network error: #{e.message}"
    end

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
      return handle_auth_error(body, status) if status == 401
      return handle_client_error(body, status) if client_error?(status)
      return handle_server_error(body, status) if server_error?(status)

      raise Error.new(error_message(status, body), status: status, body: body)
    end

    def coerce_body(body)
      return {} if body.nil? || body.empty?
      return body unless body.is_a?(String)

      JSON.parse(body)
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
      [400, 404, 422].include?(status)
    end

    def server_error?(status)
      (500..599).cover?(status)
    end

    def handle_auth_error(body, status)
      raise AuthenticationError.new("Unauthorized (401): check API key", status: status, body: body)
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

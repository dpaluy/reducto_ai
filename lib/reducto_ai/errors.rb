# frozen_string_literal: true

module ReductoAI
  class Error < StandardError
    attr_reader :status, :body

    def initialize(message = nil, status: nil, body: nil)
      super(message)
      @status = status
      @body = body
    end
  end

  class AuthenticationError < Error; end
  class ClientError < Error; end
  class ServerError < Error; end
  class NetworkError < Error; end
end

# frozen_string_literal: true

require "test_helper"

module Actions
  class GetVersionTest < Minitest::Test
    include TestConfig

    def setup
      setup_config
      @client = ReductoAI::Client.new
    end

    def teardown
      teardown_config
    end

    def test_fetches_version
      stub_request(:get, "https://api.example.com/version")
        .to_return(status: 200, body: { version: "1.2.3" }.to_json, headers: { "Content-Type" => "application/json" })

      action = ReductoAI::Actions::GetVersion.new(client: @client)
      response = action.call

      assert_equal "1.2.3", response["version"]
    end
  end
end

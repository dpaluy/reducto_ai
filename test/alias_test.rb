# frozen_string_literal: true

require "test_helper"

class AliasTest < Minitest::Test
  def test_alias_constant_defined
    assert defined?(::ReductoAi), "ReductoAi alias should be defined"
    assert_equal ::ReductoAI, ::ReductoAi
  end
end

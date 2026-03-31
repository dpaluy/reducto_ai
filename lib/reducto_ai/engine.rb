# frozen_string_literal: true

module ReductoAI
  # Rails engine for automatic initialization in Rails applications.
  #
  # Provides Rails integration for the ReductoAI gem, enabling automatic
  # loading and configuration within Rails applications.
  #
  # @api private
  if defined?(::Rails)
    class Engine < ::Rails::Engine
      isolate_namespace ReductoAI
    end
  end
end

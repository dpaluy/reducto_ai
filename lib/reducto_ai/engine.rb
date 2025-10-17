# frozen_string_literal: true

module ReductoAI
  if defined?(Rails)
    class Engine < ::Rails::Engine
      isolate_namespace ReductoAI
    end
  end
end

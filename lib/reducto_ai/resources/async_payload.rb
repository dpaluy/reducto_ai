# frozen_string_literal: true

module ReductoAI
  module Resources
    module AsyncPayload
      private

      def normalize_input(input)
        return input unless input.is_a?(Hash)

        input[:url] || input["url"] || input
      end

      def apply_async_payload!(payload, async)
        normalized_async = normalize_async_payload(async)
        payload[:async] = normalized_async unless normalized_async.nil?
        payload
      end

      def normalize_async_payload(async)
        case async
        when nil, false
          nil
        when true
          {}
        when Hash
          deep_compact(async)
        else
          raise ArgumentError, "async must be a Hash, true, false, or nil"
        end
      end

      def deep_compact(value)
        case value
        when Hash
          value.each_with_object({}) do |(key, child_value), compacted|
            normalized_child = deep_compact(child_value)
            compacted[key] = normalized_child unless normalized_child.nil?
          end
        when Array
          value.map { |child_value| deep_compact(child_value) }.compact
        else
          value
        end
      end
    end
  end
end

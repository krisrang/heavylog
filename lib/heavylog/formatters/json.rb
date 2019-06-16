# frozen_string_literal: true

require "json"

module Heavylog
  module Formatters
    class Json
      def call(data)
        ::JSON.dump(data)
      end
    end
  end
end

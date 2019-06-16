# frozen_string_literal: true

require "active_support/ordered_options"

module Heavylog
  class OrderedOptions < ActiveSupport::OrderedOptions
    def custom_payload(&block)
      self.custom_payload_method = block
    end
  end
end

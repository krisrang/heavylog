# frozen_string_literal: true

module Heavylog
  class ProxyLogger < ::Logger
    def initialize
      super(nil)
    end

    def add(severity, message=nil, progname=nil, &block)
      Heavylog.log(severity, message, progname, &block)
    end

    def loggable?
      true
    end
  end
end

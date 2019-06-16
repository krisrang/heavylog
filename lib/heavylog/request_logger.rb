# frozen_string_literal: true

module Heavylog
  module RequestLogger
    def add(severity, message=nil, progname=nil, &block)
      super
      Heavylog.log(severity, message, progname, &block)
    end
  end
end

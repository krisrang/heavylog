# frozen_string_literal: true
require 'rack/body_proxy'

module Heavylog
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ActionDispatch::Request.new(env)
      RequestStore.store[:heavylog_request_id] = request.uuid

      @app.call(env)
    ensure
      Heavylog.finish
    end
  end
end

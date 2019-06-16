# frozen_string_literal: true

require "rack/body_proxy"

module Heavylog
  class Middleware
    def initialize(app)
      @app = app
      @assets_regex = %r(\A/{0,2}#{::Rails.application.config.assets.prefix})
    end

    def call(env)
      ignore = env["PATH_INFO"] =~ @assets_regex
      unless ignore
        request = ActionDispatch::Request.new(env)
        RequestStore.store[:heavylog_request_id] = request.uuid
        RequestStore.store[:heavylog_request_start] = Time.now.iso8601
        RequestStore.store[:heavylog_request_ip] = request.ip
      end

      @app.call(env)
    ensure
      Heavylog.finish unless ignore
    end
  end
end

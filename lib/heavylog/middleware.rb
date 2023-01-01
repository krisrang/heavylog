# frozen_string_literal: true

require "rack/body_proxy"

module Heavylog
  class Middleware
    def initialize(app)
      @app = app
      @sprockets = ::Rails.application.config.respond_to?(:assets)
      @assets_regex = @sprockets ? %r(\A/{0,2}#{::Rails.application.config.assets.prefix}) : nil
    end

    def call(env)
      ignore = (@sprockets && env["PATH_INFO"] =~ @assets_regex) ||
               (Heavylog.ignore_path && env["PATH_INFO"] =~ Heavylog.ignore_path)

      unless ignore
        request = ActionDispatch::Request.new(env)
        RequestStore.store[:heavylog_request_id] = request.uuid
        RequestStore.store[:heavylog_request_start] = Time.now.iso8601
        RequestStore.store[:heavylog_request_ip] = request.remote_ip
      end

      @app.call(env)
    ensure
      Heavylog.finish unless ignore
    end
  end
end

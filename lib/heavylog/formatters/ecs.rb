# frozen_string_literal: true

require "json"

module Heavylog
  module Formatters
    class ECS
      # mapping from heavylog standard keys to ECS https://www.elastic.co/guide/en/ecs/current/ecs-reference.html
      ECS_MAP = {
        "request_start"      => "@timestamp",
        "messages"           => "message",
        "request_id"         => "http.request.id",
        "method"             => "http.request.method",
        "format"             => "http.request.mime_type",
        "status"             => "http.response.status_code",
        "location"           => "http.response.location",
        "ip"                 => "source.address",
        "path"               => "url.original",
        "controller"         => "heavylog.controller",
        "action"             => "heavylog.action",
        "unpermitted_params" => "heavylog.unpermitted_params",
        "args"               => "heavylog.args",
        "duration"           => "heavylog.duration",
        "view_runtime"       => "heavylog.view_runtime",
        "db_runtime"         => "heavylog.db_runtime",
      }.freeze

      def call(data)
        ECS_MAP.each do |original, correct|
          data[correct] = data.delete(original) if data[original]
        end

        data["event.module"] = "heavylog"
        data["event.category"] = "web"
        data["event.dataset"] ||= data["heavylog.controller"] == "SidekiqLogger" ? "heavylog.sidekiq" : "heavylog.rails"

        if data["http.response.status_code"]
          data["event.outcome"] = (200..399).cover?(data["http.response.status_code"]) ? "success" : "failure"
        end

        data["source.ip"] ||= data["source.address"]
        data["url.path"] ||= data["url.original"]

        ::JSON.dump(data)
      end
    end
  end
end

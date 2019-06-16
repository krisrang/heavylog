# frozen_string_literal: true

require "json"
require "action_pack"
require "active_support/core_ext/class/attribute"
require "active_support/log_subscriber"
require "request_store"

module Heavylog
  class LogSubscriber < ActiveSupport::LogSubscriber
    def process_action(event)
      data = extract_request(event)
      RequestStore.store[:heavylog_request_data] = data
    end

    def redirect_to(event)
      RequestStore.store[:heavylog_location] = event.payload[:location]
    end

    def unpermitted_parameters(event)
      RequestStore.store[:heavylog_unpermitted_params] ||= []
      RequestStore.store[:heavylog_unpermitted_params].concat(event.payload[:keys])
    end

    private

    def extract_request(event)
      payload = event.payload
      data = initial_data(payload)
      data.merge!(extract_status(payload))
      data.merge!(extract_runtimes(event, payload))
      data.merge!(extract_location)
      data.merge!(extract_unpermitted_params)
      data.merge!(custom_options(event))
    end

    def initial_data(payload)
      {
        method:     payload[:method],
        path:       extract_path(payload),
        format:     extract_format(payload),
        controller: payload[:controller],
        action:     payload[:action],
      }
    end

    def extract_path(payload)
      path = payload[:path]
      strip_query_string(path)
    end

    def strip_query_string(path)
      index = path.index("?")
      index ? path[0, index] : path
    end

    def extract_format(payload)
      payload[:format]
    end

    def extract_status(payload)
      if (status = payload[:status])
        { status: status.to_i }
      elsif (error = payload[:exception])
        exception, message = error
        { status: get_error_status_code(exception), error: "#{exception}: #{message}" }
      else
        { status: 0 }
      end
    end

    def get_error_status_code(exception)
      status = ActionDispatch::ExceptionWrapper.rescue_responses[exception]
      Rack::Utils.status_code(status)
    end

    def custom_options(event)
      event.payload[:custom_payload] || {}
    end

    def extract_runtimes(event, payload)
      data = { duration: event.duration.to_f.round(2) }
      %i[view_runtime db_runtime].each do |key|
        data[key] = payload[key].to_f.round(2) if payload.key?(key)
      end
      data
    end

    def extract_location
      location = RequestStore.store[:heavylog_location]
      return {} unless location

      RequestStore.store[:heavylog_location] = nil
      { location: strip_query_string(location) }
    end

    def extract_unpermitted_params
      unpermitted_params = RequestStore.store[:heavylog_unpermitted_params]
      return {} unless unpermitted_params

      RequestStore.store[:heavylog_unpermitted_params] = nil
      { unpermitted_params: unpermitted_params }
    end
  end
end

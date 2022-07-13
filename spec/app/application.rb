# frozen_string_literal: true

module Heavylog
  class Application < Rails::Application
    config.load_defaults 6.1
    config.eager_load = false
    config.cache_classes = true
    config.consider_all_requests_local = true
    config.action_controller.perform_caching = false
    config.action_dispatch.show_exceptions = true
    config.action_controller.allow_forgery_protection = false
    config.active_support.deprecation = :stderr
    config.hosts.clear
  end
end

class TestController < ActionController::Base
  def test_action
    Rails.logger.info("logger from action")

    head :ok
  end

  def redirect_action
    redirect_to "http://redirected.com"
  end

  def raise_action
    raise StandardError, "This action raises an exception"
  end
end

Rails.application.initialize!

Rails.application.routes.draw do
  get "/test" => "test#test_action"
  get "/ignore" => "test#test_action"
  get "/redirect" => "test#redirect_action"
  get "/raise" => "test#raise_action"
end

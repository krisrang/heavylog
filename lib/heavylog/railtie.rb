# frozen_string_literal: true
module Heavylog
  class Railtie < Rails::Railtie
    config.heavylog = Heavylog::OrderedOptions.new
    config.heavylog.enabled = false
    config.heavylog.path = 'log/heavylog.log'

    initializer "heavylog.insert_middleware" do |app|
      app.config.middleware.insert_before Rails::Rack::Logger, Heavylog::Middleware
    end

    config.after_initialize do |app|
      Heavylog.setup(app) if app.config.heavylog.enabled
    end
  end
end

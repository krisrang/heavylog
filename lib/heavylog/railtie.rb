# frozen_string_literal: true

module Heavylog
  class Railtie < Rails::Railtie
    config.heavylog = Heavylog::OrderedOptions.new
    config.heavylog.enabled = false
    config.heavylog.path = "log/heavylog.log"
    config.heavylog.message_limit = 1024 * 1024 * 50 # 50MB
    config.heavylog.log_sidekiq = false
    config.heavylog.ignore_path = nil
    config.heavylog.error_handler = lambda { |e|
      Kernel.puts "HeavyLog: Error writing to log: #{e.class}: #{e.message}\n  #{e.backtrace.join("\n  ")}"
    }

    initializer "heavylog.insert_middleware" do |app|
      app.config.middleware.insert_before Rails::Rack::Logger, Heavylog::Middleware
    end

    config.after_initialize do |app|
      Heavylog.setup(app) if app.config.heavylog.enabled
    end
  end
end

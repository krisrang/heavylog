# frozen_string_literal: true

module Heavylog
  class SidekiqExceptionHandler
    def call(exception, context)
      Heavylog.log(:warn, Sidekiq.dump_json(context)) unless context.empty?
      Heavylog.log(:warn, "#{exception.class.name}: #{exception.message}")
      Heavylog.log(:warn, exception.backtrace.join("\n")) unless exception.backtrace.nil?
      Heavylog.finish_sidekiq
    end
  end
end

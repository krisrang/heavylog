module Heavylog
  class SidekiqExceptionHandler
    def call(ex, ctxHash)
      Heavylog.log(:warn, Sidekiq.dump_json(ctxHash)) if !ctxHash.empty?
      Heavylog.log(:warn, "#{ex.class.name}: #{ex.message}")
      Heavylog.log(:warn, ex.backtrace.join("\n")) unless ex.backtrace.nil?
      Heavylog.finish_sidekiq
    end
  end
end

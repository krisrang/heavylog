# frozen_string_literal: true

module Heavylog
  class SidekiqLogger
    def call(item, _queue)
      # item = {"class"=>"SuspiciousJob", "args"=>[12754545, [3858890], "invoice"], "retry"=>true, "queue"=>"default",
      #   "jid"=>"5ec968571e358497d70a3cf2", "created_at"=>1540484817.3950138, "enqueued_at"=>1540484817.395076}

      Heavylog.log_sidekiq(item["jid"], item["class"], item["args"])

      begin
        start = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)
        logger.info("start")
        yield
        logger.info("done: #{elapsed(start)} sec")
        Heavylog.finish_sidekiq
      rescue StandardError
        logger.info("fail: #{elapsed(start)} sec")
        raise
      end
    end

    private

    def elapsed(start)
      (::Process.clock_gettime(::Process::CLOCK_MONOTONIC) - start).round(3)
    end

    def logger
      Sidekiq.logger
    end
  end
end

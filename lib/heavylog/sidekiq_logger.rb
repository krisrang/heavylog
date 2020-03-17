# frozen_string_literal: true

begin
  require "sidekiq/job_logger"

  module Heavylog
    class SidekiqLogger < Sidekiq::JobLogger
      def call(item, _queue)
        # item = {"class"=>"SuspiciousJob", "args"=>[12754545, [3858890], "invoice"], "retry"=>true, "queue"=>"default",
        #   "jid"=>"5ec968571e358497d70a3cf2", "created_at"=>1540484817.3950138, "enqueued_at"=>1540484817.395076}

        Heavylog.log_sidekiq(item["jid"], item["class"], item["args"])
        super
      ensure
        Heavylog.finish_sidekiq
      end
    end
  end
rescue LoadError
end

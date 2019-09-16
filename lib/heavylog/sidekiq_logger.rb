# frozen_string_literal: true

module Heavylog
  class SidekiqLogger
    def initialize(logger=Sidekiq.logger)
      @logger = logger
    end

    def call(item, _queue)
      # item = {"class"=>"SuspiciousJob", "args"=>[12754545, [3858890], "invoice"], "retry"=>true, "queue"=>"default",
      #   "jid"=>"5ec968571e358497d70a3cf2", "created_at"=>1540484817.3950138, "enqueued_at"=>1540484817.395076}

      Heavylog.log_sidekiq(item["jid"], item["class"], item["args"])

      begin
        start = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)
        @logger.info("start")

        yield

        with_elapsed_time_context(start) do
          @logger.info("done")
        end

        Heavylog.finish_sidekiq
      rescue StandardError
        with_elapsed_time_context(start) do
          @logger.info("fail")
        end

        raise
      end
    end

    def with_job_hash_context(job_hash, &block)
      @logger.with_context(job_hash_context(job_hash), &block)
    end

    def job_hash_context(job_hash)
      # If we're using a wrapper class, like ActiveJob, use the "wrapped"
      # attribute to expose the underlying thing.
      h = {
        class: job_hash["wrapped"] || job_hash["class"],
        jid:   job_hash["jid"],
      }
      h[:bid] = job_hash["bid"] if job_hash["bid"]
      h
    end

    def with_elapsed_time_context(start, &block)
      @logger.with_context(elapsed_time_context(start), &block)
    end

    def elapsed_time_context(start)
      { elapsed: elapsed(start).to_s }
    end

    private

    def elapsed(start)
      (::Process.clock_gettime(::Process::CLOCK_MONOTONIC) - start).round(3)
    end
  end
end

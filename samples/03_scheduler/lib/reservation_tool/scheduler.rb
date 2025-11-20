# frozen_string_literal: true

require "logger"

module ReservationTool
  class Scheduler
    Job = Struct.new(
      :name,
      :interval,
      :next_run_at,
      :failures,
      :max_retries,
      :retry_backoff,
      :block,
      keyword_init: true
    )

    def initialize(time_source: -> { Time.now }, sleep_proc: ->(sec) { sleep(sec) }, logger: Logger.new($stdout))
      @time_source = time_source
      @sleep_proc = sleep_proc
      @logger = logger
      @jobs = []
    end

    def every(interval_seconds, name:, max_retries: 3, retry_backoff: 5, &block)
      raise ArgumentError, "block is required" unless block
      job = Job.new(
        name: name,
        interval: interval_seconds,
        next_run_at: now,
        failures: 0,
        max_retries: max_retries,
        retry_backoff: retry_backoff,
        block: block
      )
      jobs << job
      job
    end

    def tick(current_time = now)
      jobs.each do |job|
        next if current_time < job.next_run_at

        execute(job, current_time)
      end
    end

    def run(loop_sleep: 1)
      loop do
        tick
        sleep_proc.call(loop_sleep)
      end
    end

    private

    attr_reader :jobs, :time_source, :sleep_proc, :logger

    def now
      time_source.call
    end

    def execute(job, current_time)
      logger.info("[Scheduler] #{job.name} started")
      job.block.call
      job.failures = 0
      job.next_run_at = current_time + job.interval
      logger.info("[Scheduler] #{job.name} finished")
    rescue StandardError => e
      job.failures += 1
      if job.failures <= job.max_retries
        job.next_run_at = current_time + job.retry_backoff
        logger.warn("[Scheduler] #{job.name} failed, retrying in #{job.retry_backoff}s (attempt #{job.failures}/#{job.max_retries}) - #{e.message}")
      else
        job.next_run_at = current_time + job.interval
        job.failures = 0
        logger.error("[Scheduler] #{job.name} exhausted retries - #{e.message}")
      end
    end
  end
end


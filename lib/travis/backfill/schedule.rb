require 'sidekiq/api'
require 'travis/support/registry'

module Travis
  module Backfill
    class Schedule
      MAX_QUEUE_SIZE = Integer(ENV['BACKFILL_MAX_QUEUE_SIZE'] || 10_000)

      attr_reader :store, :cursor, :num, :start, :per_page, :max, :opts, :step

      def initialize(opts)
        @opts     = opts
        @store    = Registry[:task][task].store.new(rerun: opts[:rerun])
        @num      = opts[:num]
        @start    = opts[:start]
        @max      = opts[:max]
        @per_page = opts[:per_page]
        @step     = opts[:step]
        @cursor   = last_cursor || start
        Thread.new { monitor }
      end

      MSGS = {
        start: 'Start cursor=%{cursor} start=%{start} max=%{max} per_page=%{per_page} queue=%{queue}',
        page:  'Page cursor=%{cursor} start=%{start} max=%{max} per_page=%{per_page} queue=%{queue}',
        done:  'Done cursor=%{cursor} start=%{start} max=%{max} per_page=%{per_page} queue=%{queue}',
      }

      def run
        info :start
        process
        info :done
        # sleep unless testing?
      rescue ActiveRecord::StatementInvalid => e
        puts e.message
        sleep 5
        retry
      end

      private

        def process
          while cursor < max do
            sleep 0.5 while pause?
            info :page
            process_page
            @cursor += per_page
            store_cursor
            meter
            # sleep jitter unless testing?
          end
        end

        def process_page
          time :schedule_page do
            ::Sidekiq::Client.push_bulk(
              'queue' => 'backfill',
              'class' => 'Travis::Backfill::Worker',
              'args'  => ids.map { |id| [:backfill, task, opts.merge(id: id)] }
            )
          end
        end

        def ids
          from = cursor
          to = [cursor + per_page, max].min - 1
          from.step(to: to, by: step).to_a
        end

        def testing?
          ENV['ENV'] == 'test'
        end

        def pause?
          queue.size > MAX_QUEUE_SIZE
        end

        def jitter
          rand(10).to_f / 2
        end

        def queue
          @queue ||= ::Sidekiq::Queue.new('backfill')
        end

        def last_cursor
          value = redis.get("backfill.#{task}.cursor.#{num}").to_i
          value = start if value < start
          value
        end

        def store_cursor
          redis.sadd('backfill.cursors', "backfill.#{task}.cursor.#{num}")
          redis.set("backfill.#{task}.cursor.#{num}", cursor)
        end

        def task
          task = opts[:task] || fail('Backfill task name not given.')
          task.to_sym
        end

        def info(msg)
          msg = MSGS[msg] % { cursor: cursor, start: start, max: max, per_page: per_page, queue: queue.size }
          logger.info "[#{num}] #{msg}"
        end

        def monitor
          loop do
            gauge_cursor
            gauge_queue_size
            gauge_redis_memory
            sleep 5
          end
        rescue => e
          puts e.message, e.backtrace
        end

        def gauge_cursor
          metrics.gauge "backfill.#{task}.schedule_cursor.#{num}", cursor
        end

        def gauge_queue_size
          metrics.gauge 'backfill.queue_size', queue.size
        end

        def gauge_redis_memory
          metrics.gauge 'backfill.redis_memory', redis.info['used_memory'].to_i
        end

        def meter
          metrics.meter "backfill.#{task}.schedule"
        end

        def time(key, &block)
          metrics.time "backfill.#{task}.#{key}", &block
        end

        def metrics
          Backfill.metrics
        end

        def redis
          Backfill.redis
        end

        def logger
          Backfill.logger
        end
      end
  end
end

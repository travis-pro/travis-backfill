require 'sidekiq/cli' # force server mode for connection pool size (hrm?)
require 'travis/backfill/schedule'

module Travis
  module Backfill
    class Cli
      class Schedule < Struct.new(:args, :opts)
        include Cl::Cmd

        register 'schedule'

        purpose 'Schedule tasks for backfilling records'

        MSGS = {
          announce: 'Starting scheduling on %d shards size=%d.'
        }

        DEFAULTS = {
          # TODO make defaults dynamic per task key
          offset:   ENV['BACKFILL_REQUEST_UPDATE_SCHEDULE_OFFSET'] || 0,
          threads:  ENV['BACKFILL_REQUEST_UPDATE_SCHEDULE_SHARDS'] || 1,
          per_page: ENV['BACKFILL_REQUEST_UPDATE_SCHEDULE_PAGE']   || 1000,
          rerun:    ENV['BACKFILL_REQUEST_UPDATE_SCHEDULE_RERUN']
        }

        on '-o', '--offset OFFSET', 'Starting point for N shards' do |value|
          opts[:offset] = value.to_i
        end

        on '-p', '--per_page PER_PAGE', 'Number of records to retrieve at a time (query batch size)' do |value|
          opts[:per_page] = value.to_i
        end

        on '-r', '--rerun', 'Start over and re-schedule all records' do
          opts[:rerun] = true
        end

        on '-s', '--shards SHARDS', 'Number of scheduling shards' do |value|
          opts[:threads] = value.to_i
        end

        on '-t', '--task TASK', 'The task to perform per record' do |value|
          opts[:task] = value
        end

        def run
          announce
          1.upto(threads) do |num|
            start = (num - 1) * count + offset
            Thread.new { schedule(num, start) }
          end
          sleep
        end

        def announce
          puts MSGS[:announce] % [threads, count, count + offset]
        end

        def schedule(num, start)
          Backfill::Schedule.new(opts.merge(num: num, start: start, count: count)).run
        rescue => e
          puts e.message, e.backtrace
          sleep 2
          retry
        end

        def offset
          opts[:offset].to_i
        end

        def count
          count = max_id / threads * 2
          log = Math.log10(count).floor
          count = (count / (10.0 ** log)).ceil * 10 ** log / 2
        end

        def max_id
          @max_id ||= Registry[:task][task].store.new.max_id
        end

        def threads
          opts[:threads] || 1
        end

        def task
          opts[:task]
        end

        def opts
          @opts ||= defaults.merge(super)
        end

        def defaults
          compact(DEFAULTS).map { |key, value| [key, key == :rerun ? value : value.to_i] }.to_h
        end

        def compact(hash)
          hash.reject { |_, value| value.nil? }
        end
      end
    end
  end
end

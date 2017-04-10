require 'travis/backfill/schedule'

module Travis
  module Backfill
    class Cli
      class Schedule < Struct.new(:args, :opts)
        include Cl::Cmd

        register 'schedule'

        purpose 'Schedule tasks for backfilling records'

        DEFAULTS = {
          # TODO defaults should be per task, e.g. BACKFILL_PULL_REQUEST_SCHEDULE_OFFSET
          offset:   ENV['PULL_REQUESTS_SCHEDULE_OFFSET'] || 0,
          count:    ENV['PULL_REQUESTS_SCHEDULE_COUNT']  || (ENV['ENV'] == 'production' ? 10_000_000 : 250_000),
          threads:  ENV['PULL_REQUESTS_SCHEDULE_SHARDS'] || (ENV['ENV'] == 'production' ? 6 : 3),
          per_page: ENV['PULL_REQUESTS_SCHEDULE_PAGE']   || 10_000
        }

        on '-c', '--count COUNT', 'Total number of records to schedule per shard' do |value|
          opts[:count] = value.to_i
        end

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
          1.upto(threads) do |num|
            start = (num - 1) * count + offset
            Thread.new { schedule(num, start) }
          end
          sleep
        end

        def schedule(num, start)
          Backfill::Schedule.new(opts.merge(num: num, start: start)).run
        rescue => e
          puts e.message, e.backtrace
          sleep 2
          retry
        end

        def offset
          opts[:offset].to_i
        end

        def count
          opts[:count].to_i
        end

        def threads
          opts[:threads] || 1
        end

        def opts
          @opts ||= defaults.merge(super)
        end

        def defaults
          compact(DEFAULTS).map { |key, value| [key, value.to_i] }.to_h
        end

        def compact(hash)
          hash.reject { |_, value| value.nil? }
        end
      end
    end
  end
end

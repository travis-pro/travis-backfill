require 'sidekiq/cli' # force server mode for connection pool size (hrm?)
require 'travis/backfill/schedule'

module Travis
  module Backfill
    class Cli
      class Schedule < Cl::Cmd
        description 'Schedule tasks for backfilling records'

        MSGS = {
          announce: 'Starting scheduling on %d shards size=%d.'
        }

        opt '-o', '--offset OFFSET', 'Starting point for N shards', type: :int
        opt '-p', '--per_page PER_PAGE', 'Number of records to retrieve at a time (query batch size)', type: :int
        opt '-s', '--shards SHARDS', 'Number of scheduling shards', type: :int, default: 1
        opt '-t', '--task TASK', 'The task to perform per record'
        opt '-r', '--rerun', 'Start over and re-schedule all records'

        def run
          announce
          1.upto(shards) do |num|
            start = (num - 1) * count + offset
            Thread.new { schedule(num, start) }
          end
          sleep
        end

        def announce
          puts MSGS[:announce] % [shards, count, count + offset]
        end

        def schedule(num, start)
          Backfill::Schedule.new(opts.merge(num: num, start: start, count: count)).run
        rescue => e
          puts e.message, e.backtrace
          sleep 2
          retry
        end

        def count
          count = max_id / shards * 2
          log = Math.log10(count).floor
          count = (count / (10.0 ** log)).ceil * 10 ** log / 2
        end

        def max_id
          @max_id ||= Registry[:task][task].store.new.max_id
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

        def defaults
          @defaults ||= {
            offset:   ENV.fetch("#{task.upcase}_UPDATE_SCHEDULE_OFFSET", 0).to_i,
            shards:  ENV.fetch("#{task.upcase}_UPDATE_SCHEDULE_SHARDS", 1).to_i,
            per_page: ENV.fetch("#{task.upcase}_UPDATE_SCHEDULE_PAGE", 1000).to_i,
            rerun:    ENV.fetch("#{task.upcase}_UPDATE_SCHEDULE_RERUN", false)
          }
        end
      end
    end
  end
end

require 'sidekiq/cli' # force server mode for connection pool size (hrm?)
require 'travis/backfill/helper/hash'
require 'travis/backfill/helper/memoize'
require 'travis/backfill/schedule'

module Travis
  module Backfill
    class Cli
      class Schedule < Cl::Cmd
        include Helper::Hash, Memoize

        description 'Schedule tasks for backfilling records'

        MSGS = {
          announce: 'Starting scheduling on %d shards.'
        }

        arg :task, 'The task to perform per record', required: true

        # producer options
        opt '-o', '--offset OFFSET', 'Starting point for N shards', type: :int, default: 0
        opt '-s', '--shards SHARDS', 'Number of scheduling shards (threads)', type: :int, default: 1
        opt '-p', '--per_page PER_PAGE', 'Query batch size', type: :int, default: 1000
        opt '-r', '--rerun', 'Start over and re-schedule all records'

        # worker options
        opt '--step Step', 'Number of records to step', type: :int, default: 1
        opt '--param PARAM', 'Additional params to pass', type: :array

        def run
          announce
          1.upto(shards) do |num|
            start = (num - 1) * per_page + offset
            threads << Thread.new { schedule(num, start) }
          end
          threads.each(&:join)
        end

        def announce
          puts MSGS[:announce] % [shards, per_page]
        end

        def schedule(num, start)
          opts = self.opts.merge(num: num, params: params, task: task, start: start, max: start + count)
          Backfill::Schedule.new(opts).run
        rescue => e
          puts e.message, e.backtrace
          sleep 2
          retry
        end

        def count
          max_id / shards
        end

        # def count
        #   count = max_id / shards * 2
        #   log = Math.log10(count).floor
        #   count = (count / (10.0 ** log)).ceil * 10 ** log / 2
        # end
        # memoize :count

        def max_id
          # Registry[:task][task].store.new(opts).max_id
          10_000
        end
        memoize :max_id

        def params
          symbolize(Array(param).map { |str| str.split('=') })
        end

        def threads
          @threads ||= []
        end
      end
    end
  end
end

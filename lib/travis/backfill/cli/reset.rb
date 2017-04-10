require 'sidekiq/api'
require 'travis/backfill/schedule'

module Travis
  module Backfill
    class Cli
      class Reset < Struct.new(:args, :opts)
        include Cl::Cmd

        register 'reset'

        purpose 'Reset backfilling scheduling cursors, and clear the Sidekiq queue.'

        def run
          reset_cursors
          clear_queue
        end

        private

          def reset_cursors
            return puts('No cursors found.') unless cursors.any?
            puts 'Resetting cursors:'
            puts cursors
            cursors.each { |cursor| redis.del(cursor) }
            puts 'Done.'
          end

          def clear_queue
            return puts('Sidekiq queue is empty.') if queue.size == 0
            puts "Clearing #{queue.size} jobs from the queue."
            queue.clear
          end

          def queue
            @queue ||= ::Sidekiq::Queue.new('backfill')
          end

          def cursors
            @cursors ||= redis.smembers('backfill.cursors')
          end

          def redis
            Backfill.redis
          end
      end
    end
  end
end

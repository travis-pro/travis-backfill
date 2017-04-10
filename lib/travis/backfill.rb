require 'travis/logger'
require 'travis/encrypt'
require 'travis/metrics'
require 'travis/backfill/cli'
require 'travis/backfill/config'
require 'travis/backfill/record'
require 'travis/backfill/store'
require 'travis/backfill/task'
require 'travis/backfill/worker'
require 'travis/support/redis_pool'
require 'travis/support/database'
require 'travis/support/sidekiq'

module Travis
  module Backfill
    class << self
      attr_reader :config, :logger, :metrics, :redis
      attr_writer :logger

      def setup
        @config  = Config.load
        @logger  = Logger.new(STDOUT)
        @redis   = RedisPool.new(config.redis.to_h)
        @metrics = Metrics.setup(config.metrics.to_h, logger)

        Database.connect(config.database.to_h)
        Sidekiq.setup(config)
        Encrypt.setup(config.encryption)
      end
    end

    setup
  end
end

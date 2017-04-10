module Support
  module Redis
    def self.included(const)
      const.let(:redis) { Travis::Backfill.redis }
      const.after { redis.flushall }
    end
  end
end

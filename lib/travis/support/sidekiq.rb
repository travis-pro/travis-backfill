require 'sidekiq'

module Travis
  module Sidekiq
    def setup(config)
      ::Sidekiq::Logging.logger.level = Logger::WARN

      ::Sidekiq.configure_server do |c|
        c.redis = {
          url: config.redis.url,
          namespace: config.sidekiq.namespace
        }

        c.logger.level = ::Logger::const_get(config.sidekiq.log_level.upcase.to_s)

        if pro?
          c.reliable_fetch!
          c.reliable_scheduler!
        end
      end

      ::Sidekiq.configure_client do |c|
        c.redis = {
          url: config.redis.url,
          namespace: config.sidekiq.namespace
        }

        if pro?
          ::Sidekiq::Client.reliable_push!
        end
      end
    end

    def pro?
      ::Sidekiq::NAME == 'Sidekiq Pro'
    end

    extend self
  end
end

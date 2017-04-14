require 'travis/config'

module Travis
  module Backfill
    class Config < Travis::Config
      define database:   { adapter: 'postgresql', database: "travis_#{env}", encoding: 'unicode', min_messages: 'warning', pool: 25, reaping_frequency: 60, prepared_statements: false, variables: { statement_timeout: 10000 } },
             redis:      { url: 'redis://localhost:6379' },
             sidekiq:    { namespace: 'sidekiq', pool_size: 1, log_level: :warn },
             encryption: { key: ENV['TRAVIS_ENCRYPT_KEY'] || 'secret' * 10 },
             logger:     { thread_id: true },
             github:     { api_url: 'https://api.github.com' },
             oauth2:     {},
             librato:    {},
             metrics:    { reporter: 'librato' }

      def metrics
        super.to_h.merge(librato: librato.to_h.merge(source: librato_source), graphite: graphite)
      end

      def librato_source
        ENV['LIBRATO_SOURCE'] || super
      end
    end
  end
end

require 'active_record'

module Travis
  class Database < Struct.new(:config, :logger)
    class << self
      def connect(config, logger = nil)
        new(config, logger).connect
      end
    end

    MSGS = {
      setup: 'Setting up database connection with: %s (%s)',
      count: 'Database connections on %s: size=%s, count=%s, reserved=%s, available=%s, reserved keys=%p'
    }

    def connect
      log_connection_info if logger
      const.default_timezone = :utc
      const.establish_connection(config)
      const.logger = logger
    end

    private

      def log_connection_info
        skip = [:adapter, :host, :port, :username, :password, :encoding, :min_messages]
        logger.info(MSGS[:setup] % [except(config, *skip).inspect, const.name])
      end

      def start_log_connection_counts
        @thread = Thread.new do
          loop { log_connection_counts }
        end
      end

      def log_connection_counts
        pool      = const.connection_pool
        size      = pool.size
        count     = pool.connections.size
        reserved  = pool.instance_variable_get(:@reserved_connections).size
        keys      = pool.instance_variable_get(:@reserved_connections).keys
        available = pool.instance_variable_get(:@available).instance_variable_get(:@queue).size
        logger.info(MSGS[:count] % [const.name, size, count, reserved, available, keys])
        sleep 60
      rescue Exception => e
        logger.error([e.message].concat(e.backtrace).join("\n"))
      end

      def const
        ActiveRecord::Base
      end

      def except(hash, *keys)
        hash.reject { |key, _| keys.include?(key) }
      end
  end
end

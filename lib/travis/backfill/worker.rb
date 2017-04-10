require 'travis/backfill'

module Travis
  module Backfill
    class Worker
      include ::Sidekiq::Worker

      def perform(service, task, params)
        params = symbolize_keys(params)
        logger.info "Backfilling #{task} id=#{params[:id]}"
        Registry[:task][task].new(params).run
      end

      private

        def logger
          Backfill.logger
        end

        def symbolize_keys(hash)
          hash.map { |key, value| [key.to_sym, value] }.to_h
        end
    end
  end
end

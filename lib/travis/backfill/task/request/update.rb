require 'json'
require 'travis/backfill/helper/metrics'
require 'travis/backfill/helper/memoize'
require 'travis/support/registry'

module Travis
  module Backfill
    module Task
      module Request
        class Update < Struct.new(:params)
          def self.store
            Registry[:store][:request]
          end

          include Helper::Hash, Memoize, Logging, Metrics, Registry

          register :task, 'request:update'

          def run
            return unless request
            task 'pull_request:update'
            task 'sender:update'
            task 'tag:update'
          end
          time :run

          private

            def task(key)
              const = Registry[:task][key]
              task  = const.new(request: request, commit: commit, build: build, data: data)
              task.run if task.run?
            end

            def request
              ::Request.find_by_id(params[:id])
            end
            memoize :request

            def commit
              request.commit
            end
            memoize :commit

            def build
              request.builds.first
            end
            memoize :build

            def data
              data = request.payload.payload
              data = JSON.parse(data) rescue nil if data.is_a?(String) && data[0, 2] == '{"'
              data = data || {}
              Helper::Payload.new(data)
            rescue => e
              Helper::Payload.new({})
            end
            memoize :data
        end
      end
    end
  end
end

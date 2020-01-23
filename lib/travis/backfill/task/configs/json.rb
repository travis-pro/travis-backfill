require 'json'
require 'travis/backfill/task/base'

module Travis
  module Backfill
    module Task
      module Configs
        class Json < Base
          register :task, 'configs_json'

          def self.store
            Registry[:store][:configs]
          end

          def run
            query "update #{type}_configs set config_json = config where id between #{from} and #{to}"
          end
          time :run

          private

            def type
              params[:type]
            end

            def from
              params[:id]
            end

            def to
              from + params[:step]
            end

            def query(query)
              ActiveRecord::Base.connection.execute(query)
            end
        end
      end
    end
  end
end

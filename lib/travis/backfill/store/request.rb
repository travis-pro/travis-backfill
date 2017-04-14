require 'travis/backfill/github/pull_request'
require 'travis/support/registry'

module Travis
  module Backfill
    module Store
      class Request < Struct.new(:opts)
        include Registry

        register :store, :request

        def max_id
          ::Request.maximum(:id).to_i
        end

        def ids_within(range)
          scope = ::Request.where(id: range)
          scope = scope.where('pull_request_id IS NULL OR sender_id IS NULL OR tag_id IS NULL') unless rerun?
          scope.order(:id).pluck(:id)
        end

        private

          def rerun?
            opts[:rerun]
          end

          def opts
            super || {}
          end
      end
    end
  end
end

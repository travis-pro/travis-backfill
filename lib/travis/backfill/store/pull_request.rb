require 'travis/backfill/github/pull_request'
require 'travis/support/registry'

module Travis
  module Backfill
    module Store
      module PullRequest
        class Base < Struct.new(:opts)
          include Registry

          def ids_within(range)
            scope = ::PullRequest.where(id: range)
            scope = scope.where(state: nil) unless rerun?
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

        class State < Base
          register :store, 'pull_request:state'
        end

        class Sender < Base
          register :store, 'pull_request:sender'
        end

        class Create < Struct.new(:opts)
          include Registry

          register :store, 'pull_request:create'

          def ids_within(range)
            scope = Request.where(id: range, event_type: :pull_request)
            scope = scope.where(pull_request_id: nil) unless rerun?
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
end

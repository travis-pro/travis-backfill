require 'travis/backfill/github/pull_request'
require 'travis/support/registry'

module Travis
  module Backfill
    module Store
      module Tag
        class Create < Struct.new(:opts)
          include Registry

          register :store, 'tag:create'

          def ids_within(range)
            scope = Request.where(id: range).joins(:commit)
            scope = scope.where('ref LIKE ?', '%/tags/%')
            scope = scope.where(tag_id: nil) unless rerun?
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

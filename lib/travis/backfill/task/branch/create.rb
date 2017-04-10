require 'json'
require 'travis/support/registry'

module Travis
  module Backfill
    module Task
      module Branch
        class Create < Struct.new(:params)
          include Registry

          register :task, 'branch:create'

          Payload = Struct.new(:value) do
            def method_missing(name)
              Payload.new(value.nil? ? nil : value[name.to_s])
            end
          end

          def run
            # record ? update : create
            # meter :run
            # update_request unless record.id == request.branch_id
            # update_commit  unless record.id == commit.branch_id
            # update_build   unless record.id == build.branch_id
          end

          # create_table :tags do |t|
          #   t.belongs_to :repository
          #   t.string :name
          #   t.integer :last_build_id
          #   t.boolean :exists_on_github
          #   t.timestamps
          # end
          #
          # change_table :requests do |t|
          #   t.belongs_to :branch
          #   t.belongs_to :tag
          # end
          #
          # change_table :commits do |t|
          #   t.belongs_to :branch
          #   t.belongs_to :tag
          # end
          #
          # change_table :builds do |t|
          #   t.belongs_to :branch
          #   t.belongs_to :tag
          # end
        end
      end
    end
  end
end

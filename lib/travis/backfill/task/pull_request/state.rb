require 'travis/support/registry'

module Travis
  module Backfill
    module Task
      module PullRequest
        class State < Struct.new(:params)
          include Registry

          register :task, 'pull_request:state'

          def run
            record.update_attributes!(state: data[:state])
          end

          private

            def record
              ::PullRequest.find(id)
            end

            def data
              Github::PullRequest.new(repo: repo.slug, number: number, tokens: tokens).data
            end

            def id
              params[:id]
            end

            def repo
              record.repository
            end

            def number
              record.number
            end

            def tokens
              User.where(id: user_ids).pluck(:github_oauth_token).compact
            end

            def user_ids
              Permission.where(repository_id: repo.id).pluck(:user_id)
            end
          end

          def permissions(attrs)
            Record::Permission.where(attrs.merge(repository_id: repo_id))

            def params
              super || {}
            end
        end
      end
    end
  end
end


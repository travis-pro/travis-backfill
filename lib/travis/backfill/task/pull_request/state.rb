require 'travis/backfill/helper/hash'
require 'travis/backfill/helper/metrics'
require 'travis/backfill/helper/memoize'
require 'travis/support/registry'

module Travis
  module Backfill
    module Task
      module PullRequest
        class State < Struct.new(:params)
          include Helper::Hash, Memoize, Metrics, Registry

          register :task, 'pull_request:state'

          def run?
            !pull_request.state && repo && number
          end

          def run
            update
          end
          meter :run

          private

            def update
              pull_request.update_attributes!(state: data[:state])
            end

            def data
              Github::PullRequest.new(repo: repo.slug, number: number, tokens: tokens).data
            end

            def pull_request
              params[:pull_request]
            end

            def repo
              pull_request.repository
            end
            memoize :repo

            def number
              pull_request.number
            end

            def request
              params[:request]
            end

            def tokens
              User.where(id: user_ids).map(&:github_oauth_token).compact
            end

            def user_ids
              Permission.where(repository_id: repo.id).pluck(:user_id)
            end
        end
      end
    end
  end
end


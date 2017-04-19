require 'json'
require 'travis/backfill/helper/hash'
require 'travis/backfill/helper/logging'
require 'travis/backfill/helper/metrics'
require 'travis/backfill/helper/memoize'
require 'travis/support/registry'

# The first request that is a :pull_request was id=313589 on 2012-04-19 05:44:12.

module Travis
  module Backfill
    module Task
      module PullRequest
        class Update < Struct.new(:params)
          include Helper::Hash, Logging, Metrics, Registry

          register :task, 'pull_request:update'

          attr_reader :record

          def run?
            valid? && incomplete?
          end

          def run
            @record = find_or_create
            update
            update_state   unless record.state
            update_request unless request.pull_request_id
            update_build   unless build.nil? || build.pull_request_id
          end
          # time :run
          meter :run

          private

            def valid?
              request.pull_request? && data.pull_request.number
            end

            def incomplete?
              request.pull_request_id.nil? || request.pull_request.state.nil? || build.try(:pull_request_id).nil?
            end

            def find_or_create
              find || create
            rescue ActiveRecord::RecordNotUnique => e
              warn "Pull request record not uniq for request=#{request.id}. Retrying."
              sleep 0.01
              retry
            end

            def find
              ::PullRequest.where(only(attrs, :repository_id, :number)).first
            end
            # time :find

            def create
              ::PullRequest.create(attrs)
            end
            # time :create

            def update
              record.update_attributes(except(attrs, :created_at))
            end
            # time :update

            def update_request
              request.pull_request = record
              request.save!
            end
            # time :update_request

            def update_build
              build.pull_request = record
              build.save!
            end
            # time :update_build

            def update_state
              Registry[:task]['pull_request:state'].new(pull_request: record).run
            end

            def attrs
              @attrs ||= {
                repository_id:       request.repository_id,
                number:              data.pull_request.number.value,
                title:               data.pull_request.title.value,
                head_repo_github_id: data.pull_request.head.repo.id.value,
                head_repo_slug:      data.pull_request.head.repo.full_name.value,
                head_ref:            data.pull_request.head.ref.value,
                created_at:          request.created_at
              }
            end

            def data
              params[:data]
            end

            def request
              params[:request]
            end

            def build
              params[:build]
            end
        end
      end
    end
  end
end

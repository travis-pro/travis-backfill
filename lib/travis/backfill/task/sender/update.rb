require 'json'
require 'travis/backfill/helper/hash'
require 'travis/backfill/helper/logging'
require 'travis/backfill/helper/metrics'
require 'travis/support/registry'

# The first `push` request payload that included the sender field was
# id=11004914 on 2014-09-24 06:26:35 UTC. Before that date GitHub did not
# include a sender, but a pusher, which did not include the GitHub id for the
# user, but only their login. We ignore this, as it's ambigious.
#
# Pull request payloads included the sender from the start. The first pull
# request was id=313589 on 2012-04-19 05:44:12.

module Travis
  module Backfill
    module Task
      module Sender
        class Update < Struct.new(:params)
          include Helper::Hash, Metrics, Registry

          register :task, 'sender:update'

          attr_reader :record

          def run?
            attrs[:github_id] && incomplete?
          end

          def run
            @record = find_or_create
            update_request unless request.sender_id
            update_build   unless build.nil? || build.sender_id
          end
          # time :run
          meter :run

          private

            def incomplete?
              request.sender_id.nil? || build.try(:sender_id).nil?
            end

            def find_or_create
              find || create
            rescue ActiveRecord::RecordNotUnique => e
              warn "User record not uniq for request=#{request.id}. Retrying."
              sleep 0.01
              retry
            end

            def find
              api? ? find_by_id : find_by_github_id
            end
            # time :find

            def find_by_id
              ::User.where(id: attrs[:id]).first
            end

            def find_by_github_id
              ::User.where(github_id: attrs[:github_id]).first
            end

            def create
              ::User.create(attrs)
            end
            # time :create

            def update_request
              request.sender = record
              request.save!
            end
            # time :update_request

            def update_build
              build.sender = record
              build.save!
            end
            # time :update_build

            def attrs
              @attrs ||= {
                github_id:  data.sender.id.value,
                login:      data.sender.login.value,
                avatar_url: data.sender.avatar_url.value
              }
            end

            def sender
              api? ? data.user : data.sender
            end

            def api?
              request.event_type == :api
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

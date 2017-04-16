require 'json'
require 'travis/backfill/helper/hash'
require 'travis/backfill/helper/logging'
require 'travis/backfill/helper/metrics'
require 'travis/backfill/helper/memoize'
require 'travis/support/registry'

# The first request for a tag push event was id=272455 on 2012-03-27 15:16:02

module Travis
  module Backfill
    module Task
      module Tag
        class Update < Struct.new(:params)
          include Helper::Hash, Logging, Metrics, Registry

          register :task, 'tag:update'

          attr_reader :record

          def run?
            valid? && incomplete?
          end

          def run
            @record = find_or_create
            update
            update_request # unless request.tag_id
            update_commit  unless commit.nil? # || commit.tag_id
            update_build   unless build.nil? # || build.tag_id
          end
          # time :run
          meter :run

          private

            def valid?
              request.tag? && ref && ref.start_with?('refs/tags')
            end

            def incomplete?
              # request.tag_id.nil? || commit.try(:tag_id).nil? || build.try(:tag_id).nil?
              true
            end

            def find_or_create
              find || create
            rescue ActiveRecord::RecordNotUnique => e
              warn "Tag record not uniq for request=#{request.id}. Retrying."
              sleep 0.1
              retry
            end

            def find
              ::Tag.where(only(attrs, :repository_id, :name)).first
            end
            # time :find

            def update
              record.update_attributes(except(attrs, :created_at))
            end
            # time :update

            def create
              ::Tag.create(attrs)
            end
            # time :create

            def update_request
              request.tag = record
              request.save!
            end
            # time :update_request

            def update_commit
              commit.tag = record
              commit.save!
            end
            # time :update_build

            def update_build
              build.tag = record
              build.save!
            end
            # time :update_commit

            def attrs
              @attrs ||= {
                repository_id: request.repository_id,
                last_build_id: build.try(:id),
                name: ref.to_s.sub('refs/tags/', ''),
                created_at: request.created_at
              }
            end

            def ref
              data.ref.value
            end

            def data
              params[:data]
            end

            def request
              params[:request]
            end

            def commit
              params[:commit]
            end

            def build
              params[:build]
            end
        end
      end
    end
  end
end


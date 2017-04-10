require 'json'
require 'travis/support/registry'

module Travis
  module Backfill
    module Task
      module PullRequest
        class Create < Struct.new(:params)
          include Registry

          register :task, 'pull_request:create'

          Payload = Struct.new(:value) do
            def method_missing(name)
              Payload.new(value.nil? ? nil : value[name.to_s])
            end
          end

          def run
            record ? update : create
            meter :run
            update_request unless record.id == request.pull_request_id
          end

          private

            def create
              time :create do
                @record = ::PullRequest.create(attrs)
              end
            end

            def update
              time :update do
                record.update_attributes(except(attrs, :created_at))
              end
            end

            def find
              time :find do
                ::PullRequest.where(only(attrs, :repository_id, :number)).first
              end
            end

            def update_request
              time :update_request do
                request.update_attributes(pull_request_id: record.id)
              end
            end

            def record
              @record ||= find
            end

            def attrs
              @attrs ||= {
                number: data.number.value,
                title:  data.title.value,
                repository_id: request.repository_id,
                head_repo_github_id: data.head.repo.id.value,
                head_repo_slug: data.head.repo.full_name.value,
                head_ref: data.head.ref.value,
                created_at: request.created_at
              }
            end

            def data
              @data ||= begin
                data = request.payload
                data = JSON.parse(data) rescue nil if data.is_a?(String) && data[0, 2] == '{"'
                data = data || {}
                data = data['pull_request'] || {}
                Payload.new(data)
              end
            end

            def request
              @request ||= Request.find(id)
            end

            def id
              params[:id]
            end

            def params
              super || {}
            end

            def meter(key)
              metrics.meter("backfill.#{registry_key.to_s.gsub(':', '_')}.#{key}")
            end

            def time(key, &block)
              metrics.time "backfill.#{registry_key.to_s.gsub(':', '_')}.#{key}", &block
            end

            def metrics
              Travis::Backfill.metrics
            end

            def only(hash, *keys)
              hash.select { |key, _| keys.include?(key) }.to_h
            end

            def except(hash, *keys)
              hash.reject { |key, _| keys.include?(key) }.to_h
            end
        end
      end
    end
  end
end

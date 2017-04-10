require 'json'
require 'travis/support/registry'

module Travis
  module Backfill
    module Task
      module Tag
        class Create < Struct.new(:params)
          include Registry

          register :task, 'tag:create'

          Payload = Struct.new(:value) do
            def method_missing(name)
              Payload.new(value.nil? ? nil : value[name.to_s])
            end
          end

          def run
            record ? update : create
            meter :run
            update_request if request && record.id != request.tag_id
            update_commit  if commit  && record.id != commit.tag_id
            update_build   if build   && record.id != build.tag_id
          end

          private

            def create
              time :create do
                @record = ::Tag.create(attrs)
              end
            end

            def update
              time :update do
                record.update_attributes(except(attrs, :created_at))
              end
            end

            def find
              time :find do
                ::Tag.where(only(attrs, :repository_id, :name)).first
              end
            end

            def update_request
              time :update_request do
                request.update_attributes(tag_id: record.id)
              end
            end

            def update_commit
              time :update_commit do
                commit.update_attributes(tag_id: record.id)
              end
            end

            def update_build
              time :update_build do
                build.update_attributes(tag_id: record.id)
              end
            end

            def record
              @record ||= find
            end

            def attrs
              @attrs ||= {
                repository_id: request.repository_id,
                name: data.ref.value.to_s.sub('refs/tags/', ''),
                created_at: request.created_at
              }
            end

            def data
              @data ||= begin
                data = request.payload
                data = JSON.parse(data) rescue nil if data.is_a?(String) && data[0, 2] == '{"'
                Payload.new(data || {})
              end
            end

            def request
              @request ||= Request.find(id)
            end

            def commit
              request.commit
            end

            def build
              request.builds.first
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

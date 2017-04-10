require 'travis/backfill/helper/http'
require 'travis/support/registry'

module Travis
  module Backfill
    module Github
      class PullRequest < Struct.new(:params)
        include Http, Registry

        register :github, :pull_request

        RESOURCE = '/repos/%s/pulls/%d'

        attr_reader :token

        def data
          @data ||= map(fetch)
        end

        private

          def map(data)
            compact(
              number: data['number'],
              state:  data['state'],
              title:  data['title']
            )
          end

          def unknown
            {
              'number' => params[:number],
              'state'  => 'unknown'
            }
          end

          def fetch
            with_token do
              http.get(path).body
            end
          end

          def with_token
            @token = tokens.shift
            yield
          rescue Faraday::ClientError => e
            retry if tokens.any?
            unknown
          end

          def path
            RESOURCE % [repo, number]
          end

          def http
            super(config[:github][:api_url], token: token, ssl: config[:ssl].to_h)
          end

          def repo
            params[:repo]
          end

          def number
            params[:number]
          end

          def tokens
            params[:tokens] || []
          end

          def params
            super || {}
          end

          def config
            Backfill.config
          end

          def compact(hash)
            hash.reject { |_, value| value.nil? }.to_h
          end
      end
    end
  end
end

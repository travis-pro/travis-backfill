require 'faraday'
require 'faraday_middleware'

module Travis
  module Backfill
    module Http
      class Client < Struct.new(:url, :opts)
        HEADERS  = {
          'User-Agent'     => 'travis.backfill',
          'Accept'         => 'application/vnd.github.v3+json',
          'Accept-Charset' => 'utf-8'
        }

        def get(path)
          client.get(path)
        end

        private

          def client
            Faraday.new(url: url, headers: HEADERS, ssl: ssl) do |c|
              c.use FaradayMiddleware::FollowRedirects
              c.request  :authorization, :token, token if token
              c.request  :retry
              c.response :json
              c.response :raise_error
              c.adapter  :net_http
            end
          end

          def token
            opts[:token]
          end

          def ssl
            opts[:ssl]
          end
      end

      def http(url, opts)
        Client.new(url, opts)
      end
    end
  end
end

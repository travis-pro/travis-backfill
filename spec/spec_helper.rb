ENV.delete('DATABASE_URL')
ENV['ENV'] = 'test'

require 'sidekiq/testing'
require 'support/database'
require 'support/factories'
require 'support/env'
require 'support/logger'
require 'support/redis'
require 'support/vcr'
require 'travis/backfill'

Sidekiq::Testing.inline!

RSpec.configure do |c|
  c.include Support::Env
  c.include Support::Logger
  c.include Support::Redis
end

def deep_stringify(hash)
  hash.map { |k, v| [k.to_s, v.is_a?(Hash) ? deep_stringify(v) : v] }.to_h
end

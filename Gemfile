source 'https://rubygems.org'

ruby '2.7.0' if ENV['DYNO']

gem 'travis-logger',  git: 'https://github.com/travis-ci/travis-logger'
gem 'travis-config',  git: 'https://github.com/travis-ci/travis-config'
gem 'travis-metrics', git: 'https://github.com/travis-ci/travis-metrics', ref: 'sf-unfork'
gem 'travis-encrypt'

gem 'jemalloc', git: 'https://github.com/joshk/jemalloc-rb', ref: '870facd'
gem 'sidekiq'
gem 'redis'
gem 'redis-namespace'
gem 'pg'
gem 'activerecord'
gem 'faraday'
gem 'faraday_middleware'
gem 'cl'

group :test do
  gem 'rspec'
  gem 'database_cleaner'
  gem 'factory_bot'
  gem 'vcr'
end

require 'factory_bot'

FactoryBot.define do
  factory :repository, aliases: [:repo]
  factory :request
  factory :request_config
  factory :commit
  factory :pull_request
  factory :branch
  factory :tag
  factory :build
  factory :build_config
  factory :job
  factory :job_config
  factory :user
  factory :organization, aliases: [:org]
  factory :permission
end

require 'factory_girl'

FactoryGirl.define do
  factory :repository, aliases: [:repo]
  factory :request
  factory :commit
  factory :pull_request
  factory :branch
  factory :tag
  factory :build
  factory :job
  factory :user
  factory :organization, aliases: [:org]
  factory :permission
end

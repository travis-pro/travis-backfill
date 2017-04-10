class Repository < ActiveRecord::Base
  has_many :commits
  has_many :pull_requests
  has_many :requests
  has_many :builds
  has_many :users
  belongs_to :owner

  def slug
    [owner_name, name].join('/')
  end
end

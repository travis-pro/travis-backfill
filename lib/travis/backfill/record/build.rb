class Build < ActiveRecord::Base
  belongs_to :commit
  belongs_to :request
  belongs_to :repository, autosave: true
  belongs_to :pull_request
  belongs_to :owner, polymorphic: true
  has_many   :jobs, -> { order(:id) }, as: :source, dependent: :destroy
  has_many   :stages, -> { order(:id) }

  serialize :config

  def pull_request_number
    pull_request ? pull_request.number : super
  end

  def pull_request_title
    pull_request ? pull_request.title : super
  end
end

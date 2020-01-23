require 'travis/backfill/helper/payload'

class Request < ActiveRecord::Base
  class << self
    def last_by_head_commit(head_commit)
      where(head_commit: head_commit).order(:id).last
    end
  end

  belongs_to :repository
  belongs_to :branch
  belongs_to :tag
  belongs_to :pull_request
  belongs_to :commit
  belongs_to :owner, polymorphic: true
  belongs_to :sender, polymorphic: true
  has_many   :builds, autosave: false
  has_one    :payload, autosave: true

  serialize :config
  serialize :payload

  def result
    super.try(:to_sym)
  end

  def state
    super.try(:to_sym)
  end

  def pull_request?
    event_type == 'pull_request'
  end

  def pull_request_number
    pull_request ? pull_request.number : pr.number.value if pull_request?
  end

  def pull_request_title
    pull_request ? pull_request.title : pr.title.value if pull_request?
  end

  def tag?
    event_type == 'push' && ref.to_s.start_with?('refs/tags/')
  end

  def ref
    commit && commit.ref
  end

  def payload=(payload)
    record = self.payload
    record ? record.payload = payload : build_payload(payload: payload)
  end

  private

    def pr
      @pr ||= Helper::Payload.new(payload && payload['pull_request'])
    end
end

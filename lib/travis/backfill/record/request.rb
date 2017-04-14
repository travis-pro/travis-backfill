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

  private

    def pr
      @pr ||= Payload.new(payload && payload['pull_request'])
    end

    Payload = Struct.new(:value) do
      def method_missing(name)
        Payload.new(value.nil? ? nil : value[name.to_s])
      end
    end
end

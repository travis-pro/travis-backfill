class Job < ActiveRecord::Base
  self.inheritance_column = :unused

  belongs_to :repository
  belongs_to :commit
  belongs_to :owner, polymorphic: true
  belongs_to :build, polymorphic: true, foreign_key: :source_id, foreign_type: :source_type
end

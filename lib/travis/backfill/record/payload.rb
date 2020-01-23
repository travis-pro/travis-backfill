class Payload < ActiveRecord::Base
  self.table_name = :request_payloads
  belongs_to :request
  serialize :payload
end

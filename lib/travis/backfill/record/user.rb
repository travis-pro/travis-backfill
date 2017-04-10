class User < ActiveRecord::Base
  include Travis::Encrypt::Helpers::ActiveRecord

  attr_encrypted :github_oauth_token
end

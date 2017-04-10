require 'active_record'
require 'database_cleaner'

DatabaseCleaner.orm = :active_record
DatabaseCleaner.strategy = :transaction

RSpec.configure do |c|
  c.before(:suite) { DatabaseCleaner.clean_with :truncation }
  c.before { DatabaseCleaner.start }
  c.after  { DatabaseCleaner.clean }
end

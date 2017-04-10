require 'vcr'

VCR.configure do |c|
  c.hook_into :faraday
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.configure_rspec_metadata!

  c.before_record do |i|
    i.request.headers.delete('Authorization')
  end
end

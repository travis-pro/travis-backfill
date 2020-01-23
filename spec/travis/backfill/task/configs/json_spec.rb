describe Travis::Backfill::Task::Configs::Json do
  let(:task)   { described_class.new(type: 'request', id: 1, step: 10) }
  let(:record) { RequestConfig.first }
  let(:config) { { language: 'ruby' } }

  before { create(:repo, id: 1) }
  before { create(:request_config, config: config, repository_id: 1, key: 'key') }
  before { task.run }

  subject { symbolize(record.config_json) }

  it { should eq config }
end

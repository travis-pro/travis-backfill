describe Travis::Backfill::Task::PullRequest::State, vcr: { cassette_name: 'pull_request_found' } do
  let(:repo)   { FactoryGirl.create(:repo, owner_name: 'svenfuchs', name: 'gem-release') }
  let(:record) { FactoryGirl.create(:pull_request, repository: repo, number: 1) }
  let(:params) { { id: record.id } }
  let(:task)   { described_class.new(params) }

  before { task.run }

  it { expect(record.reload.state).to eq 'closed' }
end

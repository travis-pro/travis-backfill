describe Travis::Backfill::Task::PullRequest::State do
  let(:record) { FactoryGirl.create(:pull_request, repository: repo, number: number) }
  let(:task)   { described_class.new(pull_request: record) }

  before { task.run }

  describe 'given a pull request exists', vcr: { cassette_name: 'pull_request_found' } do
    let(:repo)   { FactoryGirl.create(:repo, owner_name: 'svenfuchs', name: 'gem-release') }
    let(:number) { 1 }
    it { expect(record.reload.state).to eq 'closed' }
  end

  describe 'given a pull request does not exist', vcr: { cassette_name: 'pull_request_not_found' } do
    let(:repo)   { FactoryGirl.create(:repo, owner_name: 'svenfuchs', name: 'gem-release') }
    let(:number) { 0 }
    it { expect(record.reload.state).to eq 'unknown' }
  end
end

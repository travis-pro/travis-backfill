describe Travis::Backfill::Task::PullRequest::Update, vcr: { cassette_name: 'pull_request_found' } do
  let(:payload) { { pull_request: { number: 1, title: 'title', head: { ref: 'ref', repo: { id: 3, full_name: 'slug' } } } } }
  let(:data)    { Payload.new(deep_stringify(payload)) }
  let(:repo)    { FactoryGirl.create(:repo, owner_name: 'svenfuchs', name: 'gem-release') }
  let(:request) { FactoryGirl.create(:request, repository: repo, commit: commit, builds: [build], payload: data, created_at: 1.year.ago) }
  let(:commit)  { FactoryGirl.create(:commit) }
  let(:build)   { FactoryGirl.create(:build) }
  let(:task)    { described_class.new(request: request, commit: commit, build: build, data: data) }
  let(:record)  { request.reload.pull_request }

  before { task.run }

  shared_examples 'pull_request' do
    it { expect(record.repository_id).to eq repo.id }
    it { expect(record.number).to eq 1 }
    it { expect(record.title).to eq 'title' }
    it { expect(record.head_ref).to eq 'ref' }
    it { expect(record.head_repo_slug).to eq 'slug' }
    it { expect(record.head_repo_github_id).to eq 3 }
    it { expect(record.created_at).to eq request.created_at }

    it { expect(request.reload.pull_request_id).to eq record.id }
    it { expect(build.reload.pull_request_id).to eq record.id }
  end

  describe 'the pull_request does not exist' do
    include_examples 'pull_request'
  end

  describe 'the pull_request the record exists' do
    describe 'the pull_request is not linked to the request' do
      before { FactoryGirl.create(:pull_request, repository_id: repo.id, number: 2) }
      include_examples 'pull_request'
    end

    describe 'the pull_request is linked to the request' do
      before { FactoryGirl.create(:pull_request, repository_id: repo.id, number: 2) }
      before { request.update_attributes(pull_request: PullRequest.first) }
      include_examples 'pull_request'
    end
  end
end

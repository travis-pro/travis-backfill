describe Travis::Backfill::Task::Request::Update, vcr: { cassette_name: 'pull_request_found' } do
  let(:repo)    { create(:repo, owner_name: 'svenfuchs', name: 'gem-release') }
  let(:request) { create(:request, event_type: event, repository: repo, commit: commit, payload: deep_stringify(payload), created_at: 1.year.ago) }
  let(:commit)  { create(:commit, ref: respond_to?(:ref) ? ref : nil) }
  let!(:build)  { create(:build, request: request) }
  let(:task)    { described_class.new(id: request.id) }

  before { task.run }

  describe 'with a pull_request event' do
    let(:payload) { { pull_request: { id: 1, number: 1, title: 'title', head: { ref: 'ref', repo: { id: 3, full_name: 'slug' } } } } }
    let(:event)   { :pull_request }
    let(:record)  { request.reload.pull_request }

    it { expect(record.repository).to eq repo }
    it { expect(record.number).to eq 1 }
    it { expect(record.title).to eq 'title' }
    it { expect(record.head_ref).to eq 'ref' }
    it { expect(record.head_repo_slug).to eq 'slug' }
    it { expect(record.head_repo_github_id).to eq 3 }
    it { expect(record.created_at).to eq request.created_at }

    it { expect(request.reload.pull_request).to eq record }
    it { expect(build.reload.pull_request).to eq record }
  end

  describe 'with a tag push event' do
    let(:ref)     { 'refs/tags/v1.0.0' }
    let(:payload) { { ref: ref } }
    let(:event)   { :push }
    let(:record)  { request.reload.tag }

    it { expect(record.repository).to eq repo }
    it { expect(record.name).to eq 'v1.0.0' }
    it { expect(record.created_at).to eq request.created_at }

    it { expect(request.reload.tag).to eq record }
    it { expect(commit.reload.tag).to eq record }
    it { expect(build.reload.tag).to eq record }
  end

  describe 'sets the sender' do
    let(:payload) { { sender: { id: 2208, login: 'login', avatar_url: 'avatar_url' } } }
    let(:event)   { :push }
    let(:record)  { User.first }

    it { expect(record.github_id).to eq 2208 }
    it { expect(record.login).to eq 'login' }
    it { expect(record.avatar_url).to eq 'avatar_url' }

    it { expect(request.reload.sender).to eq record }
    it { expect(build.reload.sender).to eq record }
  end
end

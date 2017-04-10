describe Travis::Backfill::Task::PullRequest::Create do
  let(:data)    { { number: 2, title: 'title', head: { ref: 'ref', repo: { id: 3, full_name: 'slug' } } } }
  let(:request) { FactoryGirl.create(:request, repository_id: 1, payload: deep_stringify(pull_request: data), created_at: 1.year.ago) }
  let(:params)  { { id: request.id } }
  let(:task)    { described_class.new(params) }
  let(:record)  { request.reload.pull_request }

  before { task.run }

  shared_examples 'pull_request' do
    it { expect(request.reload.pull_request_id).to eq record.id }
    it { expect(record.repository_id).to eq 1 }
    it { expect(record.number).to eq 2 }
    it { expect(record.title).to eq 'title' }
    it { expect(record.head_ref).to eq 'ref' }
    it { expect(record.head_repo_slug).to eq 'slug' }
    it { expect(record.head_repo_github_id).to eq 3 }
    it { expect(record.created_at).to eq request.created_at }
  end

  describe 'the pull_request does not exist' do
    include_examples 'pull_request'
  end

  describe 'the pull_request the record exists' do
    describe 'the pull_request is not linked to the request' do
      before { FactoryGirl.create(:pull_request, repository_id: 1, number: 2) }
      include_examples 'pull_request'
    end

    describe 'the pull_request is linked to the request' do
      before { FactoryGirl.create(:pull_request, repository_id: 1, number: 2) }
      before { request.update_attributes(pull_request: PullRequest.first) }
      include_examples 'pull_request'
    end
  end
end

describe Travis::Backfill::Task::Tag::Update do
  let(:name)    { 'upstream/1.0.0' }
  let(:data)    { Travis::Backfill::Helper::Payload.new(deep_stringify(ref: "refs/tags/#{name}")) }
  let(:request) { create(:request, repository_id: 1, commit: commit, builds: [build], payload: deep_stringify(data), created_at: 1.year.ago) }
  let(:commit)  { create(:commit) }
  let(:build)   { create(:build) }
  let(:task)    { described_class.new(request: request, commit: commit, build: build, data: data) }
  let(:record)  { request.reload.tag }

  before { create(:repo, id: 1) }

  shared_examples 'tag' do
    before { task.run }

    it { expect(request.reload.tag_id).to eq record.id }
    it { expect(commit.reload.tag_id).to eq record.id }
    it { expect(build.reload.tag_id).to eq record.id }

    it { expect(record.repository_id).to eq 1 }
    it { expect(record.name).to eq name }
  end

  describe 'the tag does not exist' do
    include_examples 'tag'
    it { expect(record.created_at).to eq request.created_at }
  end

  describe 'the tag the record exists' do
    describe 'the tag is not linked to the request' do
      before { create(:tag, repository_id: 1, name: name) }
      include_examples 'tag'
    end

    describe 'the tag is linked to the request' do
      before { create(:tag, repository_id: 1, name: name) }
      before { request.update_attributes(tag: Tag.first) }
      include_examples 'tag'
    end
  end
end

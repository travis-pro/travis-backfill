describe Travis::Backfill::Task::Sender::Update do
  let(:payload) { { sender: { id: 2208, login: 'login', avatar_url: 'avatar_url' } } }
  let(:data)    { Payload.new(deep_stringify(payload)) }
  let(:request) { FactoryGirl.create(:request, builds: [build], payload: data, created_at: 1.year.ago) }
  let(:build)   { FactoryGirl.create(:build) }
  let(:user)    { FactoryGirl.create(:user, login: 'login', github_id: 2208) }
  let(:task)    { described_class.new(request: request, build: build, data: data) }

  shared_examples 'sender' do
    before { task.run }
    it { expect(request.reload.sender.login).to eq 'login' }
    it { expect(request.reload.sender.github_id).to eq 2208 }
    it { expect(build.reload.sender.login).to eq 'login' }
    it { expect(build.reload.sender.github_id).to eq 2208 }
  end

  describe 'the user does not exist' do
    include_examples 'sender'
  end

  describe 'the user exists' do
    describe 'the user is not linked to the request' do
      before { user }
      include_examples 'sender'
    end

    describe 'the user is linked to the request' do
      before { request.update_attributes(sender: user) }
      include_examples 'sender'
    end
  end
end

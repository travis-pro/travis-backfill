describe Travis::Backfill::Task::Sender::Update do
  let(:data)    { Payload.new(deep_stringify(payload)) }
  let(:request) { FactoryGirl.create(:request, builds: [build], payload: data, event_type: event, created_at: 1.year.ago) }
  let(:build)   { FactoryGirl.create(:build) }
  let(:user)    { FactoryGirl.create(:user, login: 'login', github_id: 2208) }
  let(:task)    { described_class.new(request: request, build: build, data: data) }

  shared_examples 'sets the sender' do
    before { task.run }
    it { expect(request.reload.sender.login).to eq 'login' }
    it { expect(request.reload.sender.github_id).to eq 2208 }
    it { expect(build.reload.sender.login).to eq 'login' }
    it { expect(build.reload.sender.github_id).to eq 2208 }
  end

  shared_examples 'sets senders' do
    describe 'the user does not exist' do
      include_examples 'sets the sender'
    end

    describe 'the user exists' do
      describe 'the user is not linked to the request' do
        before { user }
        include_examples 'sets the sender'
      end

      describe 'the user is linked to the request' do
        before { request.update_attributes(sender: user) }
        include_examples 'sets the sender'
      end
    end
  end

  describe 'a push request' do
    let(:payload) { { sender: { id: 2208, login: 'login', avatar_url: 'avatar_url' } } }
    let(:event)   { 'push' }
    include_examples 'sets senders'
  end

  describe 'an api request' do
    let(:payload) { { user: { id: user.id } } }
    let(:event)   { 'api' }
    include_examples 'sets senders'
  end
end

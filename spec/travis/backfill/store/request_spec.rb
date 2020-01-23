describe Travis::Backfill::Store::Request do
  let(:store) { described_class.new(opts) }

  before { create(:pull_request, id: 1) }
  before { create(:pull_request, id: 2) }
  before { create(:repo, id: 1) }
  before { create(:tag, id: 1, repository_id: 1) }
  before { create(:user, id: 1) }
  before { create(:request, id: 1, event_type: :pull_request, pull_request_id: 1, sender_id: 1, tag_id: 1) }
  before { create(:request, id: 2, event_type: :push, pull_request_id: 2) }
  before { create(:request, id: 3, event_type: :pull_request) }
  before { create(:request, id: 4, event_type: :pull_request) }

  describe 'not given :rerun' do
    let(:opts) { {} }
    it { expect(store.ids_within(1..3)).to eq [2, 3] }
  end

  describe 'given :rerun' do
    let(:opts) { { rerun: true } }
    it { expect(store.ids_within(1..3)).to eq [1, 2, 3] }
  end
end

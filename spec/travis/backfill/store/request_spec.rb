describe Travis::Backfill::Store::Request do
  let(:store) { described_class.new(opts) }

  before { FactoryGirl.create(:request, id: 1, event_type: :pull_request, pull_request_id: 1, sender_id: 1, tag_id: 1) }
  before { FactoryGirl.create(:request, id: 2, event_type: :push, pull_request_id: 2) }
  before { FactoryGirl.create(:request, id: 3, event_type: :pull_request) }
  before { FactoryGirl.create(:request, id: 4, event_type: :pull_request) }

  describe 'not given :rerun' do
    let(:opts) { {} }
    it { expect(store.ids_within(1..3)).to eq [2, 3] }
  end

  describe 'given :rerun' do
    let(:opts) { { rerun: true } }
    it { expect(store.ids_within(1..3)).to eq [1, 2, 3] }
  end
end

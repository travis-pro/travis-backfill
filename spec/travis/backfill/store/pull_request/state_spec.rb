describe Travis::Backfill::Store::PullRequest::State do
  let(:store) { described_class.new(opts) }

  before { FactoryGirl.create(:pull_request, id: 1) }
  before { FactoryGirl.create(:pull_request, id: 2, state: :open) }
  before { FactoryGirl.create(:pull_request, id: 3) }
  before { FactoryGirl.create(:pull_request, id: 4) }

  describe 'not given :rerun' do
    let(:opts) { {} }
    it { expect(store.ids_within(1..3)).to eq [1, 3] }
  end

  describe 'given :rerun' do
    let(:opts) { { rerun: true } }
    it { expect(store.ids_within(1..3)).to eq [1, 2, 3] }
  end
end

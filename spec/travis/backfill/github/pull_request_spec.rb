describe Travis::Backfill::Github::PullRequest do
  let(:token) { ENV['GITHUB_OAUTH_TOKEN'] }
  let(:api)   { described_class.new(repo: 'svenfuchs/gem-release', number: number, tokens: [token]) }

  describe 'a known pull request', vcr: { cassette_name: 'pull_request_found' } do
    let(:number) { 1 }
    it { expect(api.data).to eq number: 1, state: 'closed', title: "don't trample files" }
  end

  describe 'a unknown pull request', vcr: { cassette_name: 'pull_request_not_found' } do
    let(:number) { 0 }
    it { expect(api.data).to eq number: 0, state: 'unknown' }
  end
end

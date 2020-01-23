module Test
  class Store < Struct.new(:opts)
    include Travis::Registry
    register :store, :test

    def ids_within(range, opts = {})
      range.to_a
    end
  end

  class Task < Struct.new(:params)
    def self.store
      Test::Store
    end

    include Travis::Registry
    register :task, :test

    class << self
      attr_writer :count
      def count; @count ||= 0; end
    end

    def run
      self.class.count += 1
    end
  end
end

describe Travis::Backfill::Schedule do
  let(:opts)     { { task: :test, num: 1, start: 0, max: 10, per_page: 5 } }
  let(:schedule) { described_class.new(opts) }
  let(:task)     { Test::Task }
  let(:sidekiq)  { Sidekiq::Client }

  before { allow(sidekiq).to receive(:push_bulk).and_call_original }
  before { schedule.run }
  after  { task.count = 0 }

  it { expect(sidekiq).to have_received(:push_bulk).exactly(2).times }
  it { expect(task.count).to eq 10 }

  it { expect(log).to include 'Start cursor=0 start=0 max=10 per_page=5' }
  it { expect(log).to include 'Page cursor=0 start=0 max=10 per_page=5' }
  it { expect(log).to include 'Page cursor=5 start=0 max=10 per_page=5' }
  it { expect(log).to include 'Done cursor=10 start=0 max=10 per_page=5' }

  1.upto(9) do |id|
    it { expect(log).to include "Backfilling test id=#{id}" }
  end

  it { expect(log).to_not include 'Backfilling test id=10' }
end

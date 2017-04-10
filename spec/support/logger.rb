module Support
  module Logger
    def self.included(const)
      const.let(:stdout) { StringIO.new }
      const.let(:log)    { stdout.string }
      const.let(:logger) { Travis::Logger.new(stdout) }
      const.before       { Travis::Backfill.logger = logger }
    end
  end
end

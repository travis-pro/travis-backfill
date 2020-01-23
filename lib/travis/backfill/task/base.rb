require 'travis/backfill/helper/hash'
require 'travis/backfill/helper/metrics'
require 'travis/backfill/helper/memoize'
require 'travis/support/registry'

module Travis
  module Backfill
    module Task
      class Base < Struct.new(:params)
        include Helper::Hash, Memoize, Metrics, Registry
      end
    end
  end
end

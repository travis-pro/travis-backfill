module Travis
  module Backfill
    module Helper
      class Payload < Struct.new(:value)
        def method_missing(name)
          Payload.new(value.nil? ? nil : value[name.to_s])
        end
      end
    end
  end
end

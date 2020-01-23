require 'travis/support/registry'

module Travis
  module Backfill
    module Store
      class Configs < Struct.new(:opts)
        include Registry

        register :store, :configs

        def max_id
          ::Request.maximum(:id).to_i
        end

        private

          def const
            Kernel.const_get("#{type.capitalize}Config")
          end

          def type
            opts[:type]
          end
      end
    end
  end
end


module Travis
  module Backfill
    module Helper
      module Hash
        def only(hash, *keys)
          hash.select { |key, _| keys.include?(key) }.to_h
        end

        def except(hash, *keys)
          hash.reject { |key, _| keys.include?(key) }.to_h
        end

        def compact(hash)
          hash.reject { |_, value| value.nil? }
        end

        def symbolize(hash)
          hash.map { |key, value| [key.to_sym, value] }.to_h
        end
      end
    end
  end
end

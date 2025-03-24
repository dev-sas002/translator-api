module Highlighting
  # Process-local cache of built matchers, keyed by glossary version.
  #
  # Building a matcher is O(sum of term lengths); doing it on every read of
  # every translation is the part of highlighting that actually scaled with
  # glossary size. `Term belongs_to :glossary, touch: true` means any change to
  # a term bumps `glossary.updated_at`, so `cache_key_with_version` is a safe
  # cache key and an added or edited term is picked up on the next request.
  #
  # This is intentionally not `Rails.cache`: a matcher is a live object graph,
  # and marshalling it into and out of a store would cost more than rebuilding
  # it. The cache is per-process and bounded, so a many-glossary deployment
  # cannot grow it without limit.
  class MatcherCache
    DEFAULT_LIMIT = 128

    def initialize(limit: DEFAULT_LIMIT)
      @limit = limit
      @entries = {}
      @monitor = Monitor.new
    end

    # @yieldreturn [Highlighting::Matcher] built only on a miss
    def fetch(key)
      @monitor.synchronize do
        if @entries.key?(key)
          # Re-insert so insertion order doubles as least-recently-used order.
          @entries[key] = @entries.delete(key)
        else
          @entries[key] = yield
          @entries.shift while @entries.size > @limit
        end
        @entries[key]
      end
    end

    def clear
      @monitor.synchronize { @entries.clear }
    end

    def size
      @monitor.synchronize { @entries.size }
    end

    def self.instance
      @instance ||= new
    end
  end
end

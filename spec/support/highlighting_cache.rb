# Highlighting::MatcherCache lives for the life of the process and is keyed by
# glossary cache version. Transactional fixtures reuse primary keys across
# examples, so the cache is emptied between them to keep each example isolated.
RSpec.configure do |config|
  config.before { Highlighting::MatcherCache.instance.clear }
end

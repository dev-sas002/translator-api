# Glossary highlighting: given a source text and a set of glossary terms,
# produce the same text with every whole-word occurrence of a term wrapped in
# a markup pair.
#
# The namespace is deliberately free of ActiveRecord: `Matcher` and its
# subclasses take plain strings, which is what makes them cheap to test and
# cheap to benchmark (see `rake benchmark:highlighting`).
#
# Layering:
#
#   GlossaryHighlighter  -- Translation/Glossary -> String (the only AR-aware part)
#     MatcherCache       -- process-local, version-keyed reuse of built matchers
#       Matcher          -- terms + options -> match offsets   (strategy seam)
#         Automaton      -- Aho-Corasick multi-pattern search
#       Markup           -- match offsets -> marked-up String  (plugin seam)
module Highlighting
  class Error < StandardError; end

  # Raised when a caller asks for a matching strategy that is not registered.
  class UnknownStrategy < Error; end

  DEFAULT_STRATEGY = :adaptive

  @strategies = {}

  class << self
    # Registers a matching strategy. A strategy is any class with the same
    # constructor and `#matches` contract as Highlighting::Matcher. It may be
    # given as a class or, so that registration does not force the class to be
    # autoloaded at boot, as a constant name.
    def register_strategy(name, matcher_class)
      @strategies[name.to_sym] = matcher_class
    end

    def strategy(name)
      registered = @strategies.fetch(name.to_sym) do
        raise UnknownStrategy, "unknown highlighting strategy #{name.inspect} (known: #{strategy_names.join(", ")})"
      end
      registered.is_a?(Class) ? registered : registered.to_s.constantize
    end

    def strategy_names
      @strategies.keys
    end

    # Builds a matcher without touching the database.
    #
    # @param terms [Array<String>]
    # @param case_sensitive [Boolean]
    # @param strategy [Symbol]
    # @return [Highlighting::Matcher]
    def matcher_for(terms, case_sensitive: true, strategy: DEFAULT_STRATEGY)
      self.strategy(strategy).new(terms, case_sensitive: case_sensitive)
    end
  end

  # Single pass over the text; scan cost is independent of glossary size, but
  # the constant factor of a pure-Ruby scanner is high.
  register_strategy(:automaton, "Highlighting::AutomatonMatcher")
  # The alternation-of-literals implementation this endpoint started with.
  # Onigmo does the scanning in C, which wins outright until the alternation
  # gets large.
  register_strategy(:regexp, "Highlighting::RegexpMatcher")
  # Chooses between the two from the size of the glossary. The default.
  register_strategy(:adaptive, "Highlighting::AdaptiveMatcher")
end

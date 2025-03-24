module Highlighting
  # Picks a matching strategy from the size of the glossary.
  #
  # This exists because the measurements said so. `rake benchmark:highlighting`
  # compares the two strategies on the same input:
  #
  #   * Onigmo scans an alternation of literals in C, so for a small glossary
  #     the regexp strategy beats a pure-Ruby automaton by roughly 3x.
  #   * Its cost grows with the number of alternatives, while the automaton's
  #     scan time is flat in the number of terms.
  #
  # On the machine the README quotes, the two cross over between 1000 and 5000
  # terms. DEFAULT_THRESHOLD sits in that band; `HIGHLIGHT_AUTOMATON_THRESHOLD`
  # moves it without a deploy for a host where the crossover lands elsewhere.
  #
  # Not a Matcher subclass: it builds no index of its own, it only chooses.
  module AdaptiveMatcher
    DEFAULT_THRESHOLD = 2_500

    class << self
      # Matches Matcher's constructor so it can be registered as a strategy.
      def new(terms, case_sensitive: true)
        Highlighting.matcher_for(terms, case_sensitive: case_sensitive, strategy: strategy_for(terms))
      end

      def strategy_for(terms)
        (Array(terms).compact.uniq.size >= threshold) ? :automaton : :regexp
      end

      def threshold
        Integer(ENV.fetch("HIGHLIGHT_AUTOMATON_THRESHOLD", DEFAULT_THRESHOLD))
      end
    end
  end
end

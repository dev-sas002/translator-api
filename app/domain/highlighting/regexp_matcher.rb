module Highlighting
  # Reference strategy: the alternation-of-literals approach this endpoint used
  # before the automaton existed. It is retained deliberately, for two reasons:
  #
  # * `spec/domain/highlighting/strategy_parity_spec.rb` asserts that both
  #   strategies produce identical output, so the faster one cannot drift.
  # * `rake benchmark:highlighting` measures one against the other, which is
  #   where the numbers quoted in the README come from.
  #
  # It is not the default: a `Regexp.union` of N terms is recompiled on every
  # call and is scanned with backtracking, so its cost grows with the size of
  # the glossary.
  class RegexpMatcher < Matcher
    private

    def prepare
      return if terms.empty?

      # Longest first so that, at a given position, the longest alternative is
      # the one tried first.
      union = Regexp.union(terms.sort_by { |term| -term.length })
      @pattern = /(?<!\w)#{union}(?!\w)/
    end

    def raw_matches(folded)
      text = folded.string
      found = []
      position = 0

      while (match = @pattern.match(text, position))
        found << [match.begin(0), match[0].length]
        position = match.begin(0) + match[0].length
      end
      found
    end
  end
end

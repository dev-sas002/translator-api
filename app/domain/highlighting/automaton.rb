module Highlighting
  # An Aho-Corasick automaton over a fixed set of literal patterns.
  #
  # Building costs O(sum of pattern lengths). Scanning costs O(text length +
  # number of matches) and is independent of how many patterns were added,
  # which is the property that matters here: a glossary may hold thousands of
  # terms while each source text is capped at 5000 characters.
  #
  # States are indices into parallel arrays and transitions are keyed by
  # Unicode code point rather than by single-character String. Integer keys
  # hash faster than Strings and, more importantly, `String#each_codepoint`
  # allocates nothing per character where `String#each_char` allocates a
  # String — which is most of what a pure-Ruby scanner spends its time on.
  #
  # The automaton is immutable once built, so one instance can be shared across
  # requests (see Highlighting::MatcherCache).
  class Automaton
    ROOT = 0

    # @param patterns [Array<String>] literal patterns; duplicates, nils and
    #   empty strings are ignored.
    def initialize(patterns)
      @transitions = [{}]
      @failure = [ROOT]
      @outputs = [nil]

      patterns.each { |pattern| insert(pattern) }
      link_failures
      deep_freeze
    end

    # Yields every occurrence of every pattern.
    #
    # @param code_points [Array<Integer>] the text, as code points
    # @yieldparam start [Integer] index of the first character of the match
    # @yieldparam length [Integer] length of the matched pattern, in characters
    # @return [Array<Array(Integer, Integer)>] when no block is given
    def scan(code_points)
      return enum_for(:scan, code_points).to_a unless block_given?

      transitions = @transitions
      failure = @failure
      outputs = @outputs
      node = ROOT

      code_points.each_with_index do |point, index|
        node = failure[node] until node == ROOT || transitions[node].key?(point)
        node = transitions[node][point] || ROOT

        lengths = outputs[node]
        next if lengths.nil?

        lengths.each { |length| yield(index - length + 1, length) }
      end
    end

    private

    def insert(pattern)
      return if pattern.nil? || pattern.empty?

      node = ROOT
      pattern.each_codepoint do |point|
        node = @transitions[node][point] ||= add_node
      end
      (@outputs[node] ||= []) << pattern.length
      @outputs[node].uniq!
    end

    def add_node
      @transitions << {}
      @failure << ROOT
      @outputs << nil
      @transitions.size - 1
    end

    # Breadth-first construction of the failure links. A node's failure target
    # is the deepest proper suffix of its path that is also a trie path, and a
    # node inherits that target's outputs so `scan` never has to walk the
    # suffix chain.
    def link_failures
      queue = @transitions[ROOT].values
      queue.each { |child| @failure[child] = ROOT }

      until queue.empty?
        node = queue.shift

        @transitions[node].each do |point, child|
          fallback = @failure[node]
          fallback = @failure[fallback] until fallback == ROOT || @transitions[fallback].key?(point)

          @failure[child] = @transitions[fallback][point] || ROOT
          inherited = @outputs[@failure[child]]
          @outputs[child] = ((@outputs[child] || []) | inherited) unless inherited.nil?
          queue << child
        end
      end
    end

    def deep_freeze
      @transitions.each(&:freeze).freeze
      @failure.freeze
      @outputs.each { |outputs| outputs&.freeze }.freeze
      freeze
    end
  end
end

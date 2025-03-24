module Highlighting
  # Base class for matching strategies.
  #
  # A matcher turns a text into a list of non-overlapping `[start, length]`
  # character offsets, using **leftmost-longest** resolution: at any position
  # the longest term wins, and a match consumes the span it covers so a shorter
  # overlapping term cannot split it.
  #
  # Matches must also be whole-word: the character immediately before the match
  # and the character immediately after it must not be word characters. This
  # mirrors the `(?<!\w)...(?!\w)` guard the endpoint has always used, including
  # its ASCII-only reading of `\w` (Ruby's default).
  #
  # Subclasses implement `#raw_matches(folded)`, which may return overlapping
  # matches in any order; case folding, boundary filtering and leftmost-longest
  # resolution happen here, so every strategy behaves identically.
  class Matcher
    # Ruby's `\w` without the /u flag: [0-9A-Za-z_].
    DIGITS = (48..57)
    UPPERCASE = (65..90)
    LOWERCASE = (97..122)
    UNDERSCORE = 95
    CASE_OFFSET = 32
    ASCII_MAX = 127

    # The text under examination, carried as code points because that is what
    # the automaton scans, with the String form built only if a strategy needs
    # it.
    class Folded
      attr_reader :code_points

      def initialize(code_points)
        @code_points = code_points
      end

      def string
        @string ||= @code_points.pack("U*")
      end
    end

    attr_reader :terms, :case_sensitive

    def initialize(terms, case_sensitive: true)
      @case_sensitive = case_sensitive
      @terms = normalize(terms)
      prepare
    end

    def empty?
      terms.empty?
    end

    # @param text [String]
    # @return [Array<Array(Integer, Integer)>] sorted, non-overlapping
    #   `[start, length]` pairs, in character offsets.
    def matches(text)
      return [] if empty? || text.nil? || text.empty?

      code_points = text.codepoints
      resolve(raw_matches(Folded.new(fold(code_points))), code_points)
    end

    private

    # @abstract
    # @param folded [Folded]
    # @return [Array<Array(Integer, Integer)>] candidate matches, possibly
    #   overlapping and in any order.
    def raw_matches(folded)
      raise NotImplementedError, "#{self.class} must implement #raw_matches"
    end

    # Hook for subclasses to build their search structure from `terms`.
    def prepare
    end

    def normalize(terms)
      Array(terms)
        .compact
        .map { |term| fold(term.to_s.codepoints).pack("U*") }
        .reject(&:empty?)
        .uniq
        .freeze
    end

    def fold(code_points)
      return code_points if case_sensitive

      code_points.map { |point| fold_point(point) }
    end

    # Case folding that cannot shift character offsets. ASCII is handled
    # arithmetically; anything else is only folded when its lowercase form is a
    # single character. (A handful of code points, such as U+0130 LATIN CAPITAL
    # LETTER I WITH DOT ABOVE, lowercase to two characters and would otherwise
    # move every offset after them.)
    def fold_point(point)
      return point + CASE_OFFSET if UPPERCASE.cover?(point)
      return point if point <= ASCII_MAX

      lowered = [point].pack("U").downcase
      (lowered.length == 1) ? lowered.ord : point
    end

    def resolve(candidates, code_points)
      longest_at = {}

      candidates.each do |start, length|
        next unless whole_word?(code_points, start, length)

        current = longest_at[start]
        longest_at[start] = length if current.nil? || length > current
      end
      return [] if longest_at.empty?

      selected = []
      cursor = 0
      longest_at.keys.sort.each do |start|
        next if start < cursor

        length = longest_at[start]
        selected << [start, length]
        cursor = start + length
      end
      selected
    end

    def whole_word?(code_points, start, length)
      before = (start.positive? ? code_points[start - 1] : nil)

      !word_point?(before) && !word_point?(code_points[start + length])
    end

    def word_point?(point)
      return false if point.nil?

      LOWERCASE.cover?(point) || UPPERCASE.cover?(point) ||
        DIGITS.cover?(point) || point == UNDERSCORE
    end
  end
end

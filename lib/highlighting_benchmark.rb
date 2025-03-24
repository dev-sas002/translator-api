require "benchmark"

# Measures glossary highlighting against the two axes that actually grow in
# production: the number of terms in a glossary and the length of the source
# text. Runs entirely on domain objects, so it needs no database.
#
#   bundle exec rake benchmark:highlighting
class HighlightingBenchmark
  TEXT_LENGTH = 5_000
  TERM_COUNTS = [10, 100, 1_000, 5_000].freeze
  TEXT_LENGTHS = [500, 1_000, 2_500, 5_000].freeze
  BUDGET_SECONDS = 0.5

  # One definition of the column widths, used for headers and data alike.
  COMPARISON_ROW = "%-12s  %-14s  %-14s  %s"
  SHIPPED_ROW = "%-12s  %-10s  %-14s  %-14s  %s"

  def initialize(output: $stdout, seed: 20260924)
    @output = output
    @random = Random.new(seed)
  end

  def run
    line "Ruby #{RUBY_VERSION} | #{RUBY_PLATFORM} | #{Time.now.utc.strftime("%Y-%m-%d %H:%M:%SZ")}"
    line "Each figure is the mean of as many calls as fit in #{BUDGET_SECONDS}s."
    line "Adaptive threshold: #{Highlighting::AdaptiveMatcher.threshold} terms."
    line ""

    shipped_table
    line ""
    cold_table
    line ""
    warm_table
    line ""
    text_length_table
  end

  private

  # What the endpoint actually does, with the default (adaptive) strategy:
  # "rebuild" is the cost this service paid on every read before
  # Highlighting::MatcherCache existed; "cached" is what it pays now.
  def shipped_table
    line "As shipped: default strategy, one #{TEXT_LENGTH}-character text (ms/call)"
    line format(SHIPPED_ROW, "terms", "picks", "rebuild", "cached", "saved")

    TERM_COUNTS.each do |count|
      terms = terms_for(count)
      text = text_of(TEXT_LENGTH, terms)
      cached_matcher = Highlighting.matcher_for(terms)

      rebuild = measure { Highlighting.matcher_for(terms).matches(text) }
      cached = measure { cached_matcher.matches(text) }

      line format(SHIPPED_ROW, count, Highlighting::AdaptiveMatcher.strategy_for(terms),
        format("%.3f", rebuild), format("%.3f", cached), format("%.1fx", rebuild / cached))
    end
  end

  # Build the matcher *and* match: what every request costs without caching.
  def cold_table
    line "Cold: build a matcher and highlight one #{TEXT_LENGTH}-character text (ms/call)"
    line header

    TERM_COUNTS.each do |count|
      terms = terms_for(count)
      text = text_of(TEXT_LENGTH, terms)

      automaton = measure { Highlighting.matcher_for(terms, strategy: :automaton).matches(text) }
      regexp = measure { Highlighting.matcher_for(terms, strategy: :regexp).matches(text) }

      line comparison_row(count, automaton, regexp)
    end
  end

  # Match only: what a request costs once Highlighting::MatcherCache is warm.
  def warm_table
    line "Warm: matcher already built, highlight one #{TEXT_LENGTH}-character text (ms/call)"
    line header

    TERM_COUNTS.each do |count|
      terms = terms_for(count)
      text = text_of(TEXT_LENGTH, terms)
      automaton_matcher = Highlighting.matcher_for(terms, strategy: :automaton)
      regexp_matcher = Highlighting.matcher_for(terms, strategy: :regexp)

      automaton = measure { automaton_matcher.matches(text) }
      regexp = measure { regexp_matcher.matches(text) }

      line comparison_row(count, automaton, regexp)
    end
  end

  def text_length_table
    terms = terms_for(1_000)
    automaton_matcher = Highlighting.matcher_for(terms, strategy: :automaton)
    regexp_matcher = Highlighting.matcher_for(terms, strategy: :regexp)

    line "Warm, 1000 terms, growing text (ms/call)"
    line format(COMPARISON_ROW, "characters", "automaton", "regexp", "speedup")

    TEXT_LENGTHS.each do |length|
      text = text_of(length, terms)

      automaton = measure { automaton_matcher.matches(text) }
      regexp = measure { regexp_matcher.matches(text) }

      line comparison_row(length, automaton, regexp)
    end
  end

  def header
    format(COMPARISON_ROW, "terms", "automaton", "regexp", "speedup")
  end

  def comparison_row(label, automaton, regexp)
    format(COMPARISON_ROW, label, format("%.3f", automaton), format("%.3f", regexp),
      format("%.1fx", regexp / automaton))
  end

  def terms_for(count)
    Array.new(count) { |index| "term#{index}" }
  end

  # Text in which roughly one word in seven is a glossary hit, which is a
  # generous but not absurd density for a document with a glossary attached.
  def text_of(characters, terms)
    sample = terms.sample(20, random: @random)
    filler = "lorem ipsum dolor sit amet consectetur"
    text = +""
    text << "#{sample.sample(random: @random)} #{filler} " while text.length < characters
    text[0, characters]
  end

  def measure
    iterations = 0
    elapsed = 0.0

    while elapsed < BUDGET_SECONDS
      elapsed += Benchmark.realtime { yield }
      iterations += 1
    end

    (elapsed / iterations) * 1_000
  end

  def line(text)
    @output.puts(text)
  end
end

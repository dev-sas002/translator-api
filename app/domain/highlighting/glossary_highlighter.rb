module Highlighting
  # The only part of Highlighting that knows about ActiveRecord.
  #
  # Turns a Translation into its rendered `source_text`. A translation with no
  # glossary, or with a glossary that has no terms, is returned verbatim.
  class GlossaryHighlighter
    def self.call(translation, markup: Markup::DEFAULT, strategy: Highlighting::DEFAULT_STRATEGY)
      new(translation, markup: markup, strategy: strategy).call
    end

    def initialize(translation, markup: Markup::DEFAULT, strategy: Highlighting::DEFAULT_STRATEGY)
      @translation = translation
      @style = Markup.fetch(markup)
      @strategy = strategy
    end

    def call
      text = @translation.source_text
      return text if glossary.nil? || text.blank?

      @style.apply(text, matcher.matches(text))
    end

    private

    def glossary
      @translation.glossary
    end

    def matcher
      MatcherCache.instance.fetch(cache_key) do
        Highlighting.matcher_for(
          glossary.terms.pluck(:source_term),
          case_sensitive: glossary.case_sensitive?,
          strategy: @strategy
        )
      end
    end

    def cache_key
      [@strategy, glossary.cache_key_with_version, glossary.case_sensitive?].join("/")
    end
  end
end

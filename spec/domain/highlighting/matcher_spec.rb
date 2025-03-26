require "rails_helper"

# Every registered strategy must agree, character for character. The regexp
# strategy is the original implementation kept as a reference; the automaton
# strategy is the default. If they ever diverge, these examples say so.
RSpec.describe Highlighting::Matcher do
  Highlighting.strategy_names.each do |strategy_name|
    describe "the #{strategy_name} strategy" do
      def matcher(terms, strategy:, case_sensitive: true)
        Highlighting.matcher_for(terms, case_sensitive: case_sensitive, strategy: strategy)
      end

      let(:strategy) { strategy_name }

      it "returns no matches for an empty term list" do
        expect(matcher([], strategy: strategy).matches("the cat sat")).to eq([])
      end

      it "returns no matches for empty text" do
        expect(matcher(%w[cat], strategy: strategy).matches("")).to eq([])
      end

      it "matches a whole word" do
        expect(matcher(%w[cat], strategy: strategy).matches("the cat sat")).to eq([[4, 3]])
      end

      it "does not match inside a longer word" do
        expect(matcher(%w[cat], strategy: strategy).matches("concatenate cats")).to eq([])
      end

      it "matches at the very start and very end of the text" do
        expect(matcher(%w[cat], strategy: strategy).matches("cat")).to eq([[0, 3]])
      end

      it "matches every occurrence" do
        expect(matcher(%w[a], strategy: strategy).matches("a cat and a dog")).to eq([[0, 1], [10, 1]])
      end

      it "resolves overlaps leftmost-longest" do
        expect(matcher(["New", "New York"], strategy: strategy).matches("New York is big")).to eq([[0, 8]])
      end

      it "prefers the longer term regardless of the order it was given in" do
        expect(matcher(["New York", "New"], strategy: strategy).matches("New York is big")).to eq([[0, 8]])
      end

      it "treats terms as literals, not patterns" do
        expect(matcher(["5$", "net"], strategy: strategy).matches("costs 5$ (net) today"))
          .to eq([[6, 2], [10, 3]])
      end

      it "is case sensitive by default" do
        expect(matcher(%w[cat], strategy: strategy).matches("the Cat sat")).to eq([])
      end

      it "folds case when asked" do
        expect(matcher(%w[cat], strategy: strategy, case_sensitive: false).matches("the Cat sat"))
          .to eq([[4, 3]])
      end

      it "folds the terms as well as the text" do
        expect(matcher(%w[CAT], strategy: strategy, case_sensitive: false).matches("the cat sat"))
          .to eq([[4, 3]])
      end

      it "keeps offsets aligned for characters whose lowercase form is longer" do
        # "İ" (U+0130) downcases to two characters; folding it would shift every
        # offset after it, so it is left alone.
        expect(matcher(%w[cat], strategy: strategy, case_sensitive: false).matches("İ cat"))
          .to eq([[2, 3]])
      end

      it "matches multi-word terms" do
        expect(matcher(["ice cream"], strategy: strategy).matches("we ate ice cream today"))
          .to eq([[7, 9]])
      end

      it "works on non-ASCII text" do
        expect(matcher(["café"], strategy: strategy).matches("un café noir")).to eq([[3, 4]])
      end

      it "ignores blank and duplicated terms" do
        expect(matcher(["", nil, "cat", "cat"], strategy: strategy).matches("the cat sat"))
          .to eq([[4, 3]])
      end
    end
  end

  describe "strategy parity on random input" do
    let(:alphabet) { "abcde ".chars }

    it "produces identical matches for both strategies" do
      random = Random.new(20260924)

      200.times do
        terms = Array.new(random.rand(1..6)) do
          Array.new(random.rand(1..4)) { alphabet.sample(random: random) }.join.strip
        end.reject(&:empty?)
        next if terms.empty?

        text = Array.new(random.rand(0..60)) { alphabet.sample(random: random) }.join

        automaton = Highlighting.matcher_for(terms, strategy: :automaton).matches(text)
        regexp = Highlighting.matcher_for(terms, strategy: :regexp).matches(text)

        expect(automaton).to eq(regexp), "terms=#{terms.inspect} text=#{text.inspect}"
      end
    end
  end

  describe "the strategy registry" do
    it "exposes the registered strategies" do
      expect(Highlighting.strategy_names).to include(:automaton, :regexp)
    end

    it "resolves a registered strategy to its class" do
      expect(Highlighting.strategy(:automaton)).to eq(Highlighting::AutomatonMatcher)
    end

    it "raises a descriptive error for an unregistered strategy" do
      expect { Highlighting.strategy(:telepathy) }
        .to raise_error(Highlighting::UnknownStrategy, /telepathy.*automaton/m)
    end

    it "rejects a subclass that does not implement the contract" do
      incomplete = Class.new(Highlighting::Matcher)
      expect { incomplete.new(%w[cat]).matches("cat") }.to raise_error(NotImplementedError)
    end
  end
end

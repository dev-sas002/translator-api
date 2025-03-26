require "rails_helper"

RSpec.describe Highlighting::AdaptiveMatcher do
  def terms(count)
    Array.new(count) { |index| "term#{index}" }
  end

  describe ".strategy_for" do
    it "picks the regexp strategy for a small glossary" do
      expect(described_class.strategy_for(terms(10))).to eq(:regexp)
    end

    it "picks the regexp strategy just below the threshold" do
      expect(described_class.strategy_for(terms(described_class.threshold - 1))).to eq(:regexp)
    end

    it "picks the automaton strategy at the threshold" do
      expect(described_class.strategy_for(terms(described_class.threshold))).to eq(:automaton)
    end

    it "counts distinct terms, not repetitions" do
      expect(described_class.strategy_for(["cat"] * (described_class.threshold + 10))).to eq(:regexp)
    end

    it "handles an empty glossary" do
      expect(described_class.strategy_for([])).to eq(:regexp)
    end
  end

  describe ".threshold" do
    it "defaults to the measured crossover" do
      expect(described_class.threshold).to eq(described_class::DEFAULT_THRESHOLD)
    end

    it "is overridable from the environment" do
      allow(ENV).to receive(:fetch).with("HIGHLIGHT_AUTOMATON_THRESHOLD", anything).and_return("4")

      expect(described_class.threshold).to eq(4)
      expect(described_class.strategy_for(terms(4))).to eq(:automaton)
      expect(described_class.strategy_for(terms(3))).to eq(:regexp)
    end
  end

  describe ".new" do
    it "returns a regexp matcher below the threshold" do
      expect(described_class.new(terms(5))).to be_a(Highlighting::RegexpMatcher)
    end

    it "returns an automaton matcher at the threshold" do
      expect(described_class.new(terms(described_class.threshold))).to be_a(Highlighting::AutomatonMatcher)
    end

    it "passes case sensitivity through" do
      expect(described_class.new(%w[CAT], case_sensitive: false).matches("the cat sat")).to eq([[4, 3]])
    end
  end

  it "is the default strategy" do
    expect(Highlighting::DEFAULT_STRATEGY).to eq(:adaptive)
    expect(Highlighting.strategy_names).to include(:adaptive)
  end
end

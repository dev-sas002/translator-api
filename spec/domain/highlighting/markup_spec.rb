require "rails_helper"

RSpec.describe Highlighting::Markup do
  describe ".fetch" do
    it "falls back to the default style for nil" do
      expect(described_class.fetch(nil).name).to eq(described_class::DEFAULT)
    end

    it "falls back to the default style for an empty string" do
      expect(described_class.fetch("").name).to eq(described_class::DEFAULT)
    end

    it "accepts a string name" do
      expect(described_class.fetch("mark").open).to eq("<mark>")
    end

    it "raises for an unregistered style" do
      expect { described_class.fetch(:neon) }
        .to raise_error(Highlighting::Markup::Unknown, /neon.*highlight/m)
    end
  end

  describe ".register" do
    after { described_class.instance_variable_get(:@styles).delete(:xliff) }

    it "makes a new style available to the rest of the app" do
      described_class.register(:xliff, open: "<mrk>", close: "</mrk>")

      expect(described_class.names).to include(:xliff)
      expect(described_class.fetch(:xliff).apply("a cat", [[2, 3]])).to eq("a <mrk>cat</mrk>")
    end
  end

  describe "#apply" do
    subject(:style) { described_class.fetch(:highlight) }

    it "returns the text untouched when there is nothing to mark" do
      expect(style.apply("the cat sat", [])).to eq("the cat sat")
    end

    it "wraps a single match" do
      expect(style.apply("the cat sat", [[4, 3]])).to eq("the <HIGHLIGHT>cat</HIGHLIGHT> sat")
    end

    it "wraps several matches in order" do
      expect(style.apply("a cat and a dog", [[0, 1], [10, 1]]))
        .to eq("<HIGHLIGHT>a</HIGHLIGHT> cat and <HIGHLIGHT>a</HIGHLIGHT> dog")
    end

    it "wraps a match at the very end without losing the tail" do
      expect(style.apply("the cat", [[4, 3]])).to eq("the <HIGHLIGHT>cat</HIGHLIGHT>")
    end

    it "does not mutate the text it was given" do
      text = "the cat sat"
      expect { style.apply(text, [[4, 3]]) }.not_to change { text }
    end

    it "uses character offsets, not byte offsets" do
      expect(style.apply("un café noir", [[3, 4]])).to eq("un <HIGHLIGHT>café</HIGHLIGHT> noir")
    end
  end
end

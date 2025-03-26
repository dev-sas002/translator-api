require "rails_helper"

RSpec.describe Highlighting::Automaton do
  # The automaton scans code points, which is what Highlighting::Matcher hands
  # it; these examples pass text through the same conversion.
  def scan(patterns, text)
    described_class.new(patterns).scan(text.codepoints).sort
  end

  it "reports nothing for an empty pattern set" do
    expect(scan([], "anything at all")).to eq([])
  end

  it "ignores empty and nil patterns" do
    expect(scan(["", nil, "cat"], "cat")).to eq([[0, 3]])
  end

  it "finds every occurrence of a pattern" do
    expect(scan(["ab"], "abxab")).to eq([[0, 2], [3, 2]])
  end

  it "finds overlapping patterns, leaving resolution to the caller" do
    expect(scan(%w[he she hers his], "ushers")).to eq([[1, 3], [2, 2], [2, 4]])
  end

  it "finds a pattern that is a suffix of another via the failure links" do
    expect(scan(%w[abcd bcd cd d], "abcd")).to eq([[0, 4], [1, 3], [2, 2], [3, 1]])
  end

  it "matches multi-character and multi-word patterns" do
    expect(scan(["New York", "York"], "in New York")).to eq([[3, 8], [7, 4]])
  end

  it "handles non-ASCII text by character, not byte" do
    expect(scan(["café"], "un café noir")).to eq([[3, 4]])
  end

  it "is reusable across scans" do
    automaton = described_class.new(%w[cat dog])
    expect(automaton.scan("cat".codepoints)).to eq([[0, 3]])
    expect(automaton.scan("dog".codepoints)).to eq([[0, 3]])
  end

  it "is frozen once built" do
    expect(described_class.new(%w[cat])).to be_frozen
  end
end

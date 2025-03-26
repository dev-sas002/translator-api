require "rails_helper"

RSpec.describe Highlighting::MatcherCache do
  subject(:cache) { described_class.new(limit: 3) }

  it "builds on a miss" do
    built = 0
    cache.fetch("a") { built += 1 }
    expect(built).to eq(1)
  end

  it "does not rebuild on a hit" do
    built = 0
    3.times { cache.fetch("a") { built += 1 } }
    expect(built).to eq(1)
  end

  it "returns the cached value" do
    cache.fetch("a") { :first }
    expect(cache.fetch("a") { :second }).to eq(:first)
  end

  it "keys entries independently" do
    expect(cache.fetch("a") { :a }).to eq(:a)
    expect(cache.fetch("b") { :b }).to eq(:b)
  end

  it "evicts down to the limit" do
    4.times { |index| cache.fetch(index) { index } }
    expect(cache.size).to eq(3)
  end

  it "evicts the least recently used entry" do
    cache.fetch("a") { :a }
    cache.fetch("b") { :b }
    cache.fetch("c") { :c }
    cache.fetch("a") { :stale }  # "a" is now the most recently used
    cache.fetch("d") { :d }      # evicts "b"

    rebuilt = false
    cache.fetch("b") { rebuilt = true }
    expect(rebuilt).to be(true)

    expect(cache.fetch("a") { :rebuilt }).to eq(:a)
  end

  it "empties on clear" do
    cache.fetch("a") { :a }
    cache.clear
    expect(cache.size).to eq(0)
  end

  it "exposes a shared instance" do
    expect(described_class.instance).to be(described_class.instance)
  end
end

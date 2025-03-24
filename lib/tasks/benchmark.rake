namespace :benchmark do
  desc "Measure glossary highlighting against glossary size and text length"
  task highlighting: :environment do
    require_relative "../highlighting_benchmark"

    HighlightingBenchmark.new.run
  end
end

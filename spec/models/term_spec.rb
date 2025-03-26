require "rails_helper"

RSpec.describe Term, type: :model do
  describe "associations" do
    it { should belong_to(:glossary) }
  end

  describe "validations" do
    it { should validate_presence_of(:source_term) }
    it { should validate_presence_of(:target_term) }
  end
end

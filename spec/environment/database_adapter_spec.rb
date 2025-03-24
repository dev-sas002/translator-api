require "rails_helper"

RSpec.describe "Test environment configuration" do
  it "uses a SQLite database adapter in RAILS_ENV=test" do
    # This assertion ensures the suite is runnable without requiring a running
    # Postgres server. If someone switches the test adapter back to Postgres,
    # this test will fail and prompt updating local/CI setup.
    expect(ActiveRecord::Base.connection.adapter_name.downcase).to include("sqlite")
  end
end


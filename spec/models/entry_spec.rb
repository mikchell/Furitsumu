require "rails_helper"

RSpec.describe Entry, type: :model do
  it "is valid with the factory defaults" do
    expect(build(:entry)).to be_valid
  end

  it "prevents multiple entries on the same day for the same user" do
    user = create(:user)
    create(:entry, user:, recorded_on: Date.current)

    duplicate = build(:entry, user:, recorded_on: Date.current)

    expect(duplicate).not_to be_valid
  end
end

require "rails_helper"

RSpec.describe User, type: :model do
  it "is valid with the factory defaults" do
    expect(build(:user)).to be_valid
  end

  it "requires a name" do
    expect(build(:user, name: nil)).not_to be_valid
  end
end

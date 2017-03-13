require "spec_helper"

RSpec.describe ReleaseManager do
  it "has a version number" do
    expect(ReleaseManager::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end

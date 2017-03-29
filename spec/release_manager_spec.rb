require "spec_helper"

RSpec.describe ReleaseManager do
  it "has a version number" do
    expect(ReleaseManager::VERSION).not_to be nil
  end
end

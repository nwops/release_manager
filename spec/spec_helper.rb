require "bundler/setup"
require "release_manager"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def fixtures_dir
  @fixtures_dir ||= File.join(File.dirname(__FILE__), 'fixtures')
end

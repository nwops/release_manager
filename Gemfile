source ENV['GEM_SOURCE'] ||'https://rubygems.org'
# Specify your gem's dependencies in release_manager.gemspec
gem 'gitlab'
gem 'rugged', '~> 0.26'
gem 'highline', '~> 1.7'

group :test do
  gem 'pry'
  gem 'rubocop'
  gem 'rake'
  gem 'rspec'
  gem 'bundler'
  # when docker compiles this it cannot find release manager until we mount the volume
  gem 'release_manager', path: '.' if File.exists?(File.join('release_manager.gemspec'))
end

require 'release_manager/release'
require 'optparse'
require 'release_manager/version'
module ReleaseManager
  class ReleaseModCli
    def self.run
      options = {}
      OptionParser.new do |opts|
        opts.program_name = 'release-mod'
        opts.version = ReleaseManager::VERSION
        opts.on_head(<<-EOF

Summary: Bumps the module version to the next revision and 
         updates the changelog.md file with the new
         version by reading the metadata.json file. This should
         be run inside a module directory. 

        EOF
        )
        opts.on("-d", "--dry-run", "Do a dry run, without making changes") do |c|
          options[:dry_run] = c
        end
        opts.on('-a', '--auto', 'Run this script without interaction') do |c|
          options[:auto] = c
        end
        opts.on('-m', '--module-path [MODULEPATH]', "The path to the module, defaults to #{Dir.getwd}") do |c|
          options[:path] = c
        end
        opts.on('-b', '--no-bump', "Do not bump the version in metadata.json") do |c|
          options[:bump] = c
        end
        opts.on('-r', '--repo [REPO]', "The repo to use, defaults to repo found in the metadata source") do |c|
          options[:repo] = c
        end
        opts.on('--verbose', "Extra logging") do |c|
          options[:verbose] = c
        end
      end.parse!
      r = Release.new(options[:path], options)
      r.run
    end
  end
end

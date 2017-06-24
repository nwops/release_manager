# Purpose: release a new version of a module or r10k-control from the src branch by performing
#          the following tasks:
#           - bump version in metadata file
#           - bump changelog version using version in metadata file
#           - tag the code matching the version in the metadata file
#           - push to upstream
#  This script can be used on modules or r10k-control.  If using on a module
#  be sure to pass in the repo path using --repo.  The repo is where this script
#  pushes too.
#
#  You should also use the -d feature which simulates a run of the script without doing
#  anything harmful.
#
#  Run with -h to see the help
require 'release_manager/release'
require 'release_manager/remote_release'
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
        opts.on('-r', '--remote-release', "Perform a remote release (For CI systems)") do |c|
          options[:remote] = true
        end
      end.parse!
      r = options[:remote] ?
          RemoteRelease.new(options[:path], options) : Release.new(options[:path], options)
      r.run
    end
  end
end

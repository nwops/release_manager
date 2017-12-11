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

 Examples:
      release-mod -l minor
      release-mod -l patch -s patch1
      release-mod -m ~/repos/r10k-control
      

Configuration:

This script uses the following environment variables to automatically set some options, please ensure 
they exist in your shell environment.  You can set an environment variable in the shell or define 
in your shell startup files.

Shell:  export VARIABLE_NAME=value

R10K_REPO_URL            - The git repo url to r10k-control (ie. git@gitlab.com:devops/r10k-control.git)
GITLAB_API_ENDPOINT      - The api path to the gitlab server  (ie. https://gitlab_server/api/v4)
                           replace gitlab_server with your server hostname
GITLAB_API_PRIVATE_TOKEN - The gitlab user api token.  
                           You can get a token here (#{ReleaseManager.gitlab_server}/profile/personal_access_tokens), 
                           Ensure api box is checked.

Options:
        EOF
        )
        opts.on("-d", "--dry-run", "Do a dry run, without making changes") do |c|
          options[:dry_run] = c
        end
        opts.on('-a', '--auto', 'Run this script without interaction') do |c|
          options[:auto] = c 
        end
        opts.on('-l', '--level [LEVEL]', 'Semantic versioning level to bump (major,minor,patch), defaults to patch') do |c|
          options[:level] = c 
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
        opts.on('-s', '--src-branch [BRANCH]', 'The branch you want to base the release from, defaults to dev or master') do |c|
          options[:src_branch] = c
        end
        opts.on('-r', '--remote-release', "Perform a remote release (For CI systems)") do |c|
          options[:remote] = true
        end
      end.parse!

      unless ENV['GITLAB_API_ENDPOINT']
        puts "Please set the GITLAB_API_ENDPOINT environment variable".fatal
        puts "Example: export GITLAB_API_ENDPOINT=https://gitlab.com/api/v4".fatal
        exit 1
      end

      unless ENV['GITLAB_API_PRIVATE_TOKEN']
        puts "Please set the GITLAB_API_PRIVATE_TOKEN environment variable".fatal
        puts "Example: export GITLAB_API_PRIVATE_TOKEN=kdii2ljljijsldjfoa".fatal
        exit 1
      end

      # default to patch
      options[:level] ||= 'patch'

      # validate -l, --level input
      unless %w(major minor patch).include?(options[:level])
        puts "expected major minor or patch for parameter -l,  --level. You supplied #{options[:level]}.".fatal
        exit 1
      end
      r = options[:remote] ?
          RemoteRelease.new(options[:path], options) : Release.new(options[:path], options)
      r.run
    end
  end
end

#!/usr/bin/env ruby
#
# Author: Corey Osman
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
require 'json'
require 'optparse'
require_relative 'puppet_module'

class Release
  attr_reader :path, :options

  def initialize(path = Dir.getwd, options = {})
    @path = path || Dir.getwd    
    @options = options
  end
  
  def puppet_module
    @puppet_module ||= PuppetModule.new(path, upstream_repo)
  end

  def upstream_repo 
    options[:repo] || ENV['UPSTREAM_REPO']  
  end

  # @returns [String] the version found in the metadata file
  def version
     dry_run? ? puppet_module.version.next : puppet_module.version
  end

  def tag 
    return "Would have just tagged the module to #{version}" if dry_run?
    puppet_module.tag_module 
  end

  def bump 
    return "Would have just bumped the version to #{version}" if dry_run?
    puppet_module.bump_patch_version unless options[:bump]
    # save the update version to the metadata file, then commit
    puppet_module.commit_metadata
  end

  def bump_log 
    return "Would have just bumped the CHANGELOG to version #{version}" if dry_run?
    log = Changelog.new(puppet_module.mod_path, version, {:commit => true})
    log.run
  end

  def push 
    return "Would have just pushed the code and tag to #{puppet_module.source}" if dry_run?
    puppet_module.push 
  end

  def dry_run?
    options[:dry_run] == true
  end

  def auto_release?
    options[:auto] || ENV['AUTO_RELEASE'] == 'true'
  end

  # runs all the required steps to release the software 
  # currently this must be done manually by a release manager
  # 
  def release 
    # updates the metadata.js file to the nexter version
    puts bump
    # updates the changelog to the next version based on the metadata file
    puts bump_log
    # tags the r10k-module with the version found in the metadata.json file
    puts tag
    # pushes the updated code and tags to the upstream repo
    if auto_release? 
     puts push
     return
    end
    print "Ready to release version #{version} to #{puppet_module.source}\n and forever change history(y/n)?: ".yellow
    answer = gets.downcase.chomp
    if answer == 'y'
      puts push 
      $?.success?
    else
      puts "Nah, forget it, this release wasn't that cool anyways.".yellow
      false 
    end 
  end

  def add_upstream_remote
    upstream = `git config --get remote.upstream.url`.chomp
    if upstream != puppet_module.source 
      print "Ok to change your upstream repo from #{upstream}\n to #{puppet_module.source}? (y/n)"
      answer = gets.downcase.chomp
      if answer == 'y'
	# something else we can't identify
	if upstream != ''
	`git remote rm upstream`
	end
	`git remote add upstream #{puppet_module.source}`
      end
    end
    value = `git fetch upstream`
    puts value unless $?.success?
  end

  def verbose?
    options[:verbose]
  end

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
      opts.on('-m', '--module-path', "The path to the module, defaults to current working directory") do |c|
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

  def run
    begin
      puppet_module.create_dev_branch
      value = release
      unless value
	exit 1 
      end
      puts "Releasing Version #{version} to #{puppet_module.source}".green
      puts "Version #{version} has been released successfully".green 
      puts "Although this was a dry run so nothing really happended".green if dry_run?
      exit 0
    rescue InvalidMetadataSource
      puts "The puppet module's metadata.json source field must be a git url: ie. git@someserver.com:devops/module.git".red
    rescue ModNotFoundException 
      puts "Invalid module path for #{path}".red
      exit -1
    end
  end
end

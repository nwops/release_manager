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
require_relative 'puppet_module'

class Release
  attr_reader :path, :options
  include ReleaseManager::Logger

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
    if dry_run?
      logger.info "Would have just tagged the module to #{version}"
      return
    end
    puppet_module.tag_module 
  end

  def bump
    if dry_run?
      logger.info "Would have just bumped the version to #{version}"
      return
    end
    puppet_module.bump_patch_version unless options[:bump]
    # save the update version to the metadata file, then commit
    puppet_module.commit_metadata
  end

  def bump_log
    if dry_run?
      logger.info "Would have just bumped the CHANGELOG to version #{version}"
      return
    end
    log = Changelog.new(puppet_module.path, version, {:commit => true})
    log.run
  end

  def push
    if dry_run?
      logger.info "Would have just pushed the code and tag to #{puppet_module.source}"
      return
    end
    puppet_module.push_to_upstream
  end

  def dry_run?
    options[:dry_run] == true
  end

  def auto_release?
    options[:auto] || ENV['AUTO_RELEASE'] == 'true'
  end

  def check_requirements
    begin
      PuppetModule.check_requirements(puppet_module.path)
      Changelog.check_requirements(puppet_module.path)
    rescue NoUnreleasedLine
      logger.fatal "No Unreleased line in the CHANGELOG.md file, please add a Unreleased line and retry"
      exit 1
    rescue UpstreamSourceMatch
      logger.fatal "The upstream remote url does not match the source url in the metadata.json source"
      add_upstream_remote
      exit 1
    rescue InvalidMetadataSource
      logger.fatal "The puppet module's metadata.json source field must be a git url: ie. git@someserver.com:devops/module.git"
      exit 1
    rescue NoChangeLogFile
      logger.fatal "CHANGELOG.md does not exist, please create one"
      exit 1
    end
  end

  # runs all the required steps to release the software 
  # currently this must be done manually by a release manager
  # 
  def release
    unless auto_release?
      print "Have you merged your code?  Did you fetch and rebase against the upstream?  Want to continue (y/n)?: ".yellow
      answer = gets.downcase.chomp
      if answer == 'n'
        return false
      end
    end

    # updates the metadata.js file to the next version
    bump
    # updates the changelog to the next version based on the metadata file
    bump_log
    # tags the r10k-module with the version found in the metadata.json file
    tag
    # pushes the updated code and tags to the upstream repo
    if auto_release? 
     push
     return
    end
    print "Ready to release version #{version} to #{puppet_module.source}\n and forever change history(y/n)?: ".yellow
    answer = gets.downcase.chomp
    if answer == 'y'
      push
      $?.success?
    else
      puts "Nah, forget it, this release wasn't that cool anyways.".yellow
      false 
    end 
  end

  def add_upstream_remote
    answer = nil
    while answer !~ /y|n/
      print "Ok to change your upstream remote from #{puppet_module.upstream}\n to #{puppet_module.source}? (y/n): "
      answer = gets.downcase.chomp
    end
    puppet_module.add_upstream_remote if answer == 'y'
  end

  def verbose?
    options[:verbose]
  end

  def run
    begin
      check_requirements
      puppet_module.create_dev_branch
      value = release
      unless value
	      exit 1
      end
      logger.info "Releasing Version #{version} to #{puppet_module.source}"
      logger.info "Version #{version} has been released successfully"
      puts "This was a dry run so nothing actually happen".green if dry_run?
      exit 0
    rescue GitError
      logger.fatal "There was an issue when running a git command"
    rescue InvalidMetadataSource
      logger.fatal "The puppet module's metadata.json source field must be a git url: ie. git@someserver.com:devops/module.git"
    rescue ModNotFoundException
      logger.fatal "Invalid module path for #{path}"
      exit -1
    end
  end
end

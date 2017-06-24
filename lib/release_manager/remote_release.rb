require 'json'
require_relative 'puppet_module'

class RemoteRelease < Release
  attr_reader :path, :options
  include ReleaseManager::Logger

  def tag
    if dry_run?
      logger.info "Would have just tagged the module to #{version}"
      return
    end
    puppet_module.tag_module(true)
  end

  def bump
    if dry_run?
      logger.info "Would have just bumped the version to #{version}"
      return
    end
    puppet_module.bump_patch_version unless options[:bump]
    # save the update version to the metadata file, then commit
    puppet_module.commit_metadata(true)
  end

  def bump_log
    if dry_run?
      logger.info "Would have just bumped the CHANGELOG to version #{version}"
      return
    end
    log = Changelog.new(puppet_module.path, version, {:commit => true})
    log.run(true)
  end

  # runs all the required steps to release the software
  # currently this must be done manually by a release manager
  #
  def release
    puppet_module.create_dev_branch
    unless auto_release?
      print "Have you merged your code?  Did you fetch and rebase against the upstream?  Want to continue (y/n)?: ".yellow
      answer = gets.downcase.chomp
      if answer == 'n'
        return false
      end
      print "Ready to release version #{version.next} to #{puppet_module.source}\n and forever change history(y/n)?: ".yellow
      answer = gets.downcase.chomp
      if answer != 'y'
        puts "Nah, forget it, this release wasn't that cool anyways.".yellow
        return false
      end
    end
    # updates the metadata.js file to the next version
    bump
    # updates the changelog to the next version based on the metadata file
    bump_log
    # tags the r10k-module with the version found in the metadata.json file
    puppet_module.create_dev_branch  # gets the new commits
    tag
  end

  def run
    begin
      check_requirements
      exit 1 unless release
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

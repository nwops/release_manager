require 'json'
require_relative 'puppet_module'

class RemoteRelease < Release
  attr_reader :path, :options
  include ReleaseManager::Logger

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
    id = bump_log
    # tags the r10k-module with the version found in the metadata.json file
    tag(id)
  end

  def run
    begin
      check_requirements
      exit 1 unless release
      logger.info "Releasing Version #{version} to #{puppet_module.source}"
      logger.info "Version #{version} has been released successfully"
      puts "This was a dry run so nothing actually happen".green if dry_run?
      exit 0
    rescue Gitlab::Error::NotFound => e
      logger.fatal(e.message)
      logger.fatal("This probably means the user attached to the token does not have access")
      exit -1
    rescue Gitlab::Error::MissingCredentials => e
      logger.fatal(e.message)
      exit -1
    rescue Gitlab::Error::Forbidden => e
      logger.fatal(e.message)
      logger.fatal("You don't have access to modify the repository")
      exit -1
    rescue AlreadyReleased => e
      logger.warn(e.message)
      exit 0
    rescue TagExists => e
      logger.fatal(e.message)
      exit -1
    rescue GitError
      logger.fatal "There was an issue when running a git command"
    rescue InvalidMetadataSource
      logger.fatal "The puppet module's metadata.json source field must be a git url: ie. git@someserver.com:devops/module.git"
      exit -1
    rescue ModNotFoundException
      logger.fatal "Invalid module path for #{path}, is there a metadata.json file?"
      exit -1
    end
  end
end

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
    @puppet_module ||= PuppetModule.new(path, {upstream: upstream_repo,
                                               src_branch: options[:src_branch]})
  end

  # @return [String] - the url of the repository defined in the options or environment variable
  def upstream_repo
    options[:repo] || ENV['UPSTREAM_REPO']
  end

  # @returns [String] the version found in the metadata file
  def version
     dry_run? ? next_version : puppet_module.version
  end

  # @returns [String] the release level
  def level
     options[:level] || 'patch'
  end

  def next_version
    puppet_module.next_version(level)
  end

  def tag(id)
    if dry_run?
      logger.info "Would have just tagged the module to #{version}"
      return
    end
    puppet_module.tag_module(options[:remote], id)
  end

  def bump
    if dry_run?
      logger.info "Would have just bumped the version to #{version}"
      return
    end
    raise TagExists.new("Tag v#{version} already exists") if puppet_module.tag_exists?("v#{next_version}", options[:remote])
    if puppet_module.respond_to?("bump_#{level}_version".to_sym)
      version = puppet_module.public_send("bump_#{level}_version".to_sym) unless options[:bump]
    end
    # save the update version to the metadata file, then commit
    puppet_module.commit_metadata(options[:remote])
  end

  # @return [String] - sha of the commit
  def bump_log
    if dry_run?
      logger.info "Would have just bumped the CHANGELOG to version #{version}"
      return
    end
    log = Changelog.new(puppet_module.path, version, {:commit => true})
    log.run(options[:remote], puppet_module.src_branch)
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
    @loop_count = @loop_count.to_i + 1
    begin
      PuppetModule.check_requirements(puppet_module.path)
      raise AlreadyReleased.new("No new changes, skipping release") if puppet_module.already_latest?
      Changelog.check_requirements(puppet_module.path)
    rescue NoUnreleasedLine
      logger.fatal "No Unreleased line in the CHANGELOG.md file, please add a Unreleased line and retry"
      return false
    rescue UpstreamSourceMatch
      logger.warn "The upstream remote url does not match the source url in the metadata.json source"
      add_upstream_remote
      return false if @loop_count > 2
      check_requirements
    rescue InvalidMetadataSource
      logger.fatal "The puppet module's metadata.json source field must be a git url: ie. git@someserver.com:devops/module.git"
      return false
    rescue NoChangeLogFile
      logger.fatal "CHANGELOG.md does not exist, please create one"
      return false
    end
  end

  # runs all the required steps to release the software
  # currently this must be done manually by a release manager
  #
  def release
    begin
      unless auto_release?
        print "Have you merged your code?  Did you fetch and rebase against the upstream?  Want to continue (y/n)?: ".yellow
        answer = gets.downcase.chomp
        if answer == 'n'
          return false
        end
      end

      # updates the metadata.json file to the next version
      bump
      # updates the changelog to the next version based on the metadata file
      id = bump_log
      # tags the r10k-module with the version found in the metadata.json file
      tag(id)
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
    rescue Rugged::TagError => e
      logger.fatal(e.message)
      logger.fatal("You might need to rebase your branch")
      exit 1
    end
  end

  def add_upstream_remote
    if auto_release?
      puppet_module.add_upstream_remote
      return
    end
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
      exit -1 unless check_requirements
      puppet_module.create_src_branch
      value = release
      unless value
	      exit 1
      end
      logger.info "Releasing Version #{version} to #{puppet_module.source}"
      logger.info "Version #{version} has been released successfully"
      puts "This was a dry run so nothing actually happen".green if dry_run?
      exit 0
    rescue Gitlab::Error::Forbidden => e
      logger.fatal(e.message)
      logger.fatal("You don't have access to modify the repository")
      exit -1
    rescue TagExists => e
      logger.fatal(e.message)
      exit -1
    rescue GitError => e
      logger.fatal "There was an issue when running a git command\n #{e.message}"
    rescue InvalidMetadataSource
      logger.fatal "The puppet module's metadata.json source field must be a git url: ie. git@someserver.com:devops/module.git"
      exit -1
    rescue AlreadyReleased => e
      logger.warn(e.message)
      exit 0
    rescue ModNotFoundException
      logger.fatal "Invalid module path for #{path}"
      exit -1
    end
  end
end

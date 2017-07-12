# frozen_string_literal: true
require_relative 'puppetfile'
require_relative 'puppet_module'
require 'highline/import'
require 'tempfile'

class R10kDeployer
  attr_reader :options, :path, :previous_branch

  include ReleaseManager::Logger
  include ReleaseManager::VCSManager
  include ReleaseManager::Git::Utilities

  def initialize(path, opts)
    @path = path
    @options = opts
  end

  def run
    begin
      @previous_branch = options[:src_ref]
      mr, branch_name = create_mr(options[:src_ref], options[:dest_ref], options[:remote])
    ensure
      # cleanup branch, checkout previous branch
    end
    puts mr.web_url if mr
  end

  def cleanup(branch = nil)
    control_repo.checkout_branch(previous_branch, strategy: :force)
    control_repo.delete_branch(branch) if branch
  end

  alias_method :control_repo_path, :path

  def self.run(path, options)
    begin
      deploy = new(path, options)
      deploy.check_requirements
      deploy.logger.info "Deploying R10k-Control #{options[:dest_ref]} with version: #{options[:src_ref]}"
      deploy.run
    rescue Gitlab::Error::Forbidden => e
      logger.fatal(e.message)
      logger.fatal("You don't have access to modify the repository")
    rescue Gitlab::Error::MissingCredentials => e
      deploy.logger.fatal(e.message)
      code = 1
    rescue PatchError => e
      deploy.logger.fatal(e.message)
      code = 1
    rescue ModNotFoundException => e
      deploy.logger.fatal(e.message)
      code = 1
    rescue InvalidBranchName => e
      deploy.logger.fatal(e.message)
      code = 1
    rescue InvalidMetadataSource
      deploy.logger.fatal "The puppet module's metadata.json source field must be a git url: ie. git@someserver.com:devops/module.git"
      code = 1
    rescue PuppetfileNotFoundException
      deploy.logger.fatal "Cannot find the puppetfile at #{puppetfile_path}"
      code = 1
    rescue InvalidModuleNameException => e
      deploy.logger.fatal e.message
      code = 1
    rescue Gitlab::Error::NotFound => e
      deploy.logger.fatal e.message
      deploy.logger.fatal "Either the project does not exist or you do not have enough permissions"
      code = 1
    rescue Exception => e
      deploy.logger.fatal e.message
      deploy.logger.fatal e.backtrace.join("\n")
      code = 1
    ensure
      exit code.to_i
    end
  end

  def control_repo
    @control_repo ||= setup_control_repo(puppetfile.source)
  end

  def check_requirements
    raise PuppetfileNotFoundException unless File.exists?(control_repo_path)
  end

  private

  def create_mr(src_ref, dest_ref, remote = false)
    url = puppetfile.source
    message = "auto deploy #{src_ref} to #{dest_ref}"
    branch_name = "#{dest_ref}_#{rand(10000)}"
    control_repo.create_branch(branch_name, "upstream/#{dest_ref}")
    control_repo.checkout_branch(branch_name, strategy: :force )
    diff = control_repo.create_diff(src_ref,branch_name)
    return control_repo.logger.info("nothing to commit or deploy") if diff.deltas.count < 1
    Tempfile.open('git_patch') do |patchfile|
      patchfile.write(diff.patch)
      control_repo.apply_patch(patchfile.path)
      control_repo.add_all
    end
    successful_commit = control_repo.commit(message, nil, nil, false)
    control_repo.push_branch('myfork', branch_name, true) if successful_commit
    mr = control_repo.create_merge_request(control_repo.url, message, {
        source_branch: branch_name,
        target_branch: dest_ref,
        remove_source_branch: true,
        target_project_url: url
    })  if successful_commit
    return [mr, branch_name]
  end

  # @return [ControlRepo] - creates a new control repo object and clones the url unless already cloned
  # @param [String] url - the url to clone and fork
  def setup_control_repo(url)
    # clone r10k unless already cloned
    fork = create_repo_fork(url)
    c = ControlRepo.create(control_repo_path, fork.ssh_url_to_repo)
    c.add_remote(fork.ssh_url_to_repo, 'myfork',true)
    c.fetch('myfork')
    c.fetch('origin')
    c.add_remote(url, 'upstream', true)
    c.fetch('upstream')
    c
  end

  # @return [Puppetfile] - instance of Puppetfile object
  def puppetfile
    @puppetfile ||= begin
      file = options[:puppetfile] || File.join(path, 'Puppetfile')
      Puppetfile.new(file)
    end
  end

end

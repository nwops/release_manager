require 'release_manager/puppetfile'
require 'rugged'
require 'release_manager/git/utilites'

class ControlRepo
  attr_accessor :path, :repo, :url
  DEFAULT_BRANCH = ENV['CONTROL_REPO_DEFAULT_BRANCH'] || 'dev'
  DEFAULT_BRANCHES = ENV['CONTROL_REPO_DEFAULT_BRANCHES'] || %w(dev qa integration acceptance production)

  include ReleaseManager::Git::Utilities
  include ReleaseManager::Logger
  include ReleaseManager::VCSManager

  def initialize(path, url = nil)
    @path = path
    @url = url
  end

  # @return [ControlRepo] - creates a new control repo object and clones the url unless already cloned
  def self.create(path, url)
    c = ControlRepo.new(path, url)
    c.clone(url, path)
    c
  end

  def repo
    @repo ||= ::Rugged::Repository.new(path)
  end

  def puppetfile
    unless @puppetfile
      @puppetfile = Puppetfile.new(File.join(path, 'Puppetfile'))
      @puppetfile.base_path = path
    end
    @puppetfile
  end

  def commit(message, diff_obj, branch_name, remote = false)
    message = "[ReleaseManager] - #{message}"
    if remote
      actions = diff_2_commit(diff_obj)
      obj = vcs_create_commit(url, branch_name, message, actions)
      obj.id if obj
    else
      create_commit(message)
    end
  end

end

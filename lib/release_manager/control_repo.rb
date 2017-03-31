require 'release_manager/puppetfile'
require 'rugged'
require 'release_manager/git/utilites'

class ControlRepo
  attr_accessor :path, :repo, :url

  include ReleaseManager::Git::Utilities
  include ReleaseManager::Logger

  def initialize(path, url = nil)
    @path = path
    @url = url
  end

  # @return [ControlRepo] - creates a new control repo object and clones the url unless already cloned
  def self.create(path, url, branch = 'dev')
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

end

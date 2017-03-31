require 'puppetfile'
require 'rugged'

class ControlRepo
  attr_accessor :path, :repo

  def initialize(path)
    @path = path
  end

  def repo
    @repo ||= Rugged::Repository.new(path)
  end

  def create_branch(name)
    repo.branches.create(name)
    repo.checkout(name)
  end

  def puppetfile
    unless @puppetfile
      @puppetfile = Puppetfile.new(File.join(path, 'Puppetfile'))
      @puppetfile.base_path = path
    end
    @puppetfile
  end

end

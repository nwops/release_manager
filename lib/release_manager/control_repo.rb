require 'puppetfile'
require 'git'

class ControlRepo
  attr_accessor :path, :git

  def initialize(path)
    @path = path
  end

  def git
    @git ||= Git.open(path, :log => Logger.new(STDOUT))
  end

  def create_branch(name)
    git.branch(name).checkout
  end

  def puppetfile
    unless @puppetfile
      @puppetfile = Puppetfile.new(File.join(path, 'Puppetfile'))
      @puppetfile.base_path = path)
    end
    @puppetfile
  end

end

require_relative 'puppet_module'
require_relative 'control_repo'

class Sandbox
  attr_reader :modules, :name, :repos_dir, :control_repo, :module_names

  def initialize(name, modules, repos_dir)
    @name = name
    @repos_dir = repos_dir
    @module_names = modules
  end

  # @returns [Hash[PuppetModules]] an hash of puppet modules
  def modules
    unless @modules
      @modules = {}
      module_names.strip.split(',').each do |m| 
        pm = puppetfile.find_mod(m.strip.downcase)
        @modules[pm.name] = pm
      end
    end
  end

  def puppetfile 
    unless @puppetfile
      @puppetfile = Puppetfile.new(File.join(repos_dir, 'r10k-control', 'Puppetfile'))
      @puppetfile.base_path = File.join(repos_dir, 'r10k-control')
    end
    @puppetfile
  end

  def create_r10k_branch
    
  end

  def self.create

  end


end

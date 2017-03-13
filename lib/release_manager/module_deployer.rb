# frozen_string_literal: true
require_relative 'puppetfile'
require_relative 'puppet_module'
require 'optparse'
require_relative 'version'

class ModuleDeployer
# get path to puppetfile
  def puppetfile_path
    @puppetfile_path ||= options[:puppetfile] || ENV['PUPPET_FILE_PATH'] || File.expand_path("~/repos/r10k-control/Puppetfile")
  end

  def mod_path
    @mod_path ||= options[:modulepath] || ENV['MOD_DIR']
  end

  def puppet_module 
    @puppet_module ||= PuppetModule.new(mod_path)
  end

  def latest_version
    puppet_module.latest_tag
  end

  def check_requirements
    raise PuppetfileNotFoundException unless File.exists?(puppetfile_path)
    raise ModNotFoundException if !mod_path || !File.exists?(mod_path)
  end
  
  def options
    @options ||= {}
  end

  def run
    OptionParser.new do |opts|
      opts.program_name = 'deploy_mod'
      opts.version = ReleaseManager::VERSION
      opts.on('-p', "--puppetfile [PUPPETFILE]", 'Path to R10k Puppetfile, defaults to ~/repos/r10k-control/Puppetfile') do |p|
        options[:puppetfile] = p
      end
      opts.on('-m', '--modulepath MODULEPATH', 'Path to to module') do |p|
        options[:modulepath] = p
      end
    end.parse!

    begin
      check_requirements
    rescue PuppetfileNotFoundException
      puts "Cannot find the puppetfile at #{puppetfile_path}".red
      exit -1 
    rescue ModNotFoundException
      puts "Invalid module path for #{mod_path}".red
      exit -1
    end


    pf = Puppetfile.new(puppetfile_path)
    ver = pf.write_version(puppet_module.name, latest_version)
    puts "Found module #{puppet_module.name} with version : #{ver}".green
    pf.to_puppetfile
    puts "Updated module #{puppet_module.name} in Puppetfile to version : #{ver}".green
  end
end
# TODO:
# commit puppetfile
# push code to repo
# create M

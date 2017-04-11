# frozen_string_literal: true
require_relative 'puppetfile'
require_relative 'puppet_module'
class ModuleDeployer
  attr_reader :options

  def initialize(opts)
    opts[:modulepath] = Dir.getwd if opts[:modulepath].nil? 
    @options = opts
  end
  
  def puppetfile_path
    @puppetfile_path ||= options[:puppetfile] || ENV['PUPPET_FILE_PATH'] || File.expand_path("~/repos/r10k-control/Puppetfile")
  end

  def mod_path
    @mod_path ||= options[:modulepath] || ENV['MOD_DIR'] || File.expand_path(Dir.getwd)
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
  

  
  def control_repo_remote
    @control_repo_remote ||= options[:remote] || puppetfile.source
  end
  
  def puppetfile
    @puppetfile ||= Puppetfile.new(puppetfile_path)
  end

  def run
    begin
      check_requirements
      puts "Found module #{puppet_module.name} with version: #{latest_version}".green
      puts "Updated module #{puppet_module.name} in Puppetfile to version: #{latest_version}".green
      if options[:dry_run]
        puts "Would have committed with message: bump #{puppet_module.name} to version: #{latest_version}".green if options[:commit]
        puts "Would have just pushed branch: #{puppetfile.current_branch} to remote: #{control_repo_remote}".green if options[:push]
      else
        puppetfile.write_version(puppet_module.name, latest_version)
        puppetfile.write_to_file
        if options[:commit]
          puppetfile.commit("bump #{puppet_module.name} to version #{latest_version}")
          puts "Commited with message: bump #{puppet_module.name} to version #{latest_version}".green
        end
        if options[:push]
          puppetfile.push(control_repo_remote, puppetfile.current_branch)
          puts "Just pushed branch: #{puppetfile.current_branch} to remote: #{control_repo_remote}".green
        end
      end
    rescue InvalidMetadataSource
      puts "The puppet module's metadata.json source field must be a git url: ie. git@someserver.com:devops/module.git".red
    rescue PuppetfileNotFoundException
      puts "Cannot find the puppetfile at #{puppetfile_path}".red
      exit -1
    rescue InvalidModuleNameException => e
      puts e.message
      exit 1
    rescue ModNotFoundException
      puts "Invalid module path for #{mod_path}".red
      puts "This means that the metadata.json name field does not match\nthe module name found in the Puppetfile or this is not a puppet module".fatal
      exit -1
    end
  end
end

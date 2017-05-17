# frozen_string_literal: true
require_relative 'puppetfile'
require_relative 'puppet_module'
require 'highline/import'

class ModuleDeployer
  attr_reader :options
  include ReleaseManager::Logger

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
    raise ModNotFoundException if !mod_path || ! File.exists?(mod_path)
  end

  def control_repo_remote
    @control_repo_remote ||= options[:remote] || puppetfile.source
  end
  
  def puppetfile
    @puppetfile ||= Puppetfile.new(puppetfile_path)
  end

  # @param [PuppetModule] puppet_module - the puppet module to check for existance
  # raises
  def add_module(puppet_module)
    unless puppetfile.mod_exists?(puppet_module.name)
      answer = ask("The #{puppet_module.name} module does not exist, do you want to add it? (y/n): ", String) { |q| q =~ /y|n/i }.downcase
      if answer == 'y'
        puppetfile.add_module(puppet_module.name, git: puppet_module.repo, tag: "v#{puppet_module.version}") unless options[:dry_run]
      end
    end
  end

  def run
    begin
      check_requirements
      logger.info "Deploying module #{puppet_module.name} with version: #{latest_version}"
      if options[:dry_run]
        add_module(puppet_module)
        puts "Would have updated module #{puppet_module.name} in Puppetfile to version: #{latest_version}".green
        puts "Would have committed with message: bump #{puppet_module.name} to version: #{latest_version}".green if options[:commit]
        puts "Would have just pushed branch: #{puppetfile.current_branch} to remote: #{control_repo_remote}".green if options[:push]
      else
        add_module(puppet_module)
        puppetfile.write_version(puppet_module.name, latest_version)
        puppetfile.write_source(puppet_module.name, puppet_module.source)
        puppetfile.write_to_file
        logger.info "Updated module #{puppet_module.name} in Puppetfile to version: #{latest_version}"
        if options[:commit]
          puppetfile.commit("bump #{puppet_module.name} to version #{latest_version}")
          logger.info "Commited with message: bump #{puppet_module.name} to version #{latest_version}"
        end
        if options[:push]
          puppetfile.push(control_repo_remote, puppetfile.current_branch)
          logger.info "Just pushed branch: #{puppetfile.current_branch} to remote: #{control_repo_remote}"
        end
      end
    rescue InvalidMetadataSource
      logger.fatal "The puppet module's metadata.json source field must be a git url: ie. git@someserver.com:devops/module.git"
    rescue PuppetfileNotFoundException
      logger.fatal "Cannot find the puppetfile at #{puppetfile_path}"
      exit -1
    rescue InvalidModuleNameException => e
      logger.fatal e.message
      exit 1
    rescue ModNotFoundException
      logger.fatal "Invalid module path for #{mod_path}"
      puts "This means that the metadata.json name field does not match\nthe module name found in the Puppetfile or this is not a puppet module".fatal
      exit -1
    end
  end
end

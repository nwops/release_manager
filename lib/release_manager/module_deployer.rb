# frozen_string_literal: true
require_relative 'puppetfile'
require_relative 'puppet_module'
require 'optparse'
require_relative 'version'

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
  
  def self.run
    options = {}
    OptionParser.new do |opts|
      opts.program_name = 'deploy-mod'
      opts.version = ReleaseManager::VERSION
      opts.on_head(<<-EOF

Summary: Gets the version of your module found in the metadata
         and populates the r10k-control Puppetfile with the updated
         tag version. Revmoes any branch or ref reference and replaces
         with tag.  Currently it is up to you to commit and push the Puppetfile change.

EOF
)
      opts.on('-p', "--puppetfile [PUPPETFILE]", 'Path to R10k Puppetfile, defaults to ~/repos/r10k-control/Puppetfile') do |p|
        options[:puppetfile] = p
      end
      opts.on('-m', '--modulepath [MODULEPATH]', "Path to to module, defaults to: #{Dir.getwd}") do |p|
        options[:modulepath] = p
      end
      opts.on('-c', '--commit', 'Optionally, Commit the Puppetfile change') do |p|
        options[:commit] = p
      end
      opts.on('-u', '--push', 'Optionally, Push the changes to the remote') do |p|
        options[:push] = p
      end
      opts.on('-r', '--remote REMOTE', 'Optionally, spaecify a remote name or url to push changes to') do |p|
        options[:remote] = p
      end
      opts.on('-d', 'Perform a dry run without making changes') do |p|
        options[:dry_run] = p
      end
    end.parse!
    m = ModuleDeployer.new(options)
    m.run
  end

  def run
    begin
      check_requirements
      pf = Puppetfile.new(puppetfile_path)
      puts "Found module #{puppet_module.name} with version: #{latest_version}".green
      puts "Updated module #{puppet_module.name} in Puppetfile to version: #{latest_version}".green
      if options[:dry_run]
        puts "Would have committed with message: bump #{puppet_module.name} to version: #{latest_version}".green if options[:commit]
        puts "Would have just pushed branch: #{pf.current_branch} to remote: #{options[:remote]}".green if options[:remote] && options[:push]
      else
        pf.write_version(puppet_module.name, latest_version)
        pf.to_puppetfile
        if options[:commit]
          pf.commit("bump #{puppet_module.name} to version #{latest_version}")
          puts "Committed with message: bump #{puppet_module.name} to version: #{latest_version}".green
        end
        if options[:push]
          pf.push(options[:remote], pf.current_branch) if options[:remote]
          puts "Just pushed branch: #{pf.current_branch} to remote: #{options[:remote]}".green
        end
      end
    rescue InvalidMetadataSource
      puts "The puppet module's metadata.json source field must be a git url: ie. git@someserver.com:devops/module.git".red
    rescue PuppetfileNotFoundException
      puts "Cannot find the puppetfile at #{puppetfile_path}".red
      exit -1 
    rescue ModNotFoundException
      puts "Invalid module path for #{mod_path}".red
      puts "This means that the metadata.json name field does not match\nthe module name found in the Puppetfile or this is not a puppet module".fatal
      exit -1
    end
  end
end

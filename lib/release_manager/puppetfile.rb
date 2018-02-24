# frozen_string_literal: true
require_relative 'control_mod'
require_relative 'errors'
require 'fileutils'
require 'json'
require 'release_manager/puppet_module'

class Puppetfile
  attr_accessor :modules, :puppetfile, :data, :base_path, :puppetmodule
  BUMP_TYPES = %w{patch minor major}

  include ReleaseManager::Git::Utilities
  include ReleaseManager::Logger
  include ReleaseManager::VCSManager

  alias_method :path, :base_path

  # @param [String] puppetfile - the path to the puppetfile
  def initialize(puppetfile = 'Puppetfile')
    @puppetfile = puppetfile
    @puppetmodule = PuppetModule.new(base_path)
  end

  def source
    puppetmodule.source
  end

  def base_path
    @base_path ||= File.dirname(puppetfile)
  end

  def commit(message, remote = false)
    message = "[ReleaseManager] - #{message}"
    if remote
      actions = [{
         action: 'update',
         file_path: puppetfile.split(repo.workdir).last,
         content: to_s
      }]
      obj = vcs_create_commit(source, 'master', message, actions)
      obj.id if obj
    else
      write_to_file
      add_file(puppetfile)
      create_commit(message)
    end
  end

  def add_module(name, metadata)
    modules[name] = ControlMod.new(name, metadata)
  end

  # @param remote [String] - the remote name
  # @param branch [String] - the branch to push
  # @param force [Boolean] - force push , defaults to false
  # @pram tags [Boolean] - push tags, defaults to true
  def push(remote, branch, force = false, tags = true)
    push_branch(remote, branch, force)
    push_tags(remote) if tags
  end

  def data
    unless @data
      @data = File.read(puppetfile)
    end
    @data
  end

  # @return [Array[ControlMod]] - a list of control mod objects
  def modules
    unless @modules
      @modules = {}
      instance_eval(data) if data
    end
    @modules
  end

  def self.from_string(s)
    instance = new
    instance.data = s
    instance
  end

  # @param Array[String] names - find all mods with the following names
  # @return Hash[String, ControlMod] - returns the pupppet modules in a hash
  def find_mods(names)
    mods = {}
    return mods if names.nil?
    names.each do | mod_name |
      m = find_mod(mod_name)
      mods[m.name] = m
    end
    mods
  end

  # @param [String] name - the name of the mod you wish to find in the puppetfile
  # @return ControlMod - a ControlMod object
  def find_mod(name)
    mod_name = name.strip.downcase
    mod = modules[mod_name] || modules.find{ |module_name, mod| mod.repo =~ /#{mod_name}/i }
    raise InvalidModuleNameException.new("Invalid module name #{name}, cannot locate in Puppetfile") unless mod
    # since find returns an array we need to grab the element ouf of the array first
    return mod.last if mod.instance_of?(Array)
    mod
  end

  # @param [String] name - the name of the mod you wish to find in the puppetfile
  # @return [Boolean] - true if the module is found
  def mod_exists?(name)
    begin
      !!find_mod(name)
    rescue InvalidModuleNameException
      false
    end
  end

  def write_version(mod_name, version)
    mod = find_mod(mod_name)
    mod.pin_version(version)
  end

  # @param [String] mod_name - the module name found in the puppetfile
  # @param [String] src - the git url to the source
  # @option [String] branch - the branch name to pin to if provided
  # @return [ControlMod]
  def write_source(mod_name, src, branch = nil)
    mod = find_mod(mod_name)
    mod.pin_url(src)
    mod.pin_branch(branch) if branch
    mod
  end

  def bump(mod_name, type = 'patch')
    raise "Invalid type, must be one of #{BUMP_TYPES}" unless BUMP_TYPES.include?(type)
    mod = find_mod(mod_name)
    find_mod(mod_name).send("bump_#{type}_version")
  end

  def to_json(pretty = false)
    if pretty
      JSON.pretty_generate(modules)
    else
      modules.to_json
    end
  end

  def diff(a,b)
    FileUtils.compare_stream(a,b)
  end

  # @return [Boolean] - true if writing to file occurred, false otherwise
  def write_to_file
    contents = to_s
    a = StringIO.new(contents)
    b = File.new(puppetfile)
    # do not write to the file if nothing changed
    return false if FileUtils.compare_stream(a,b)
    File.write(puppetfile, to_s)
  end

  def to_s
    modules.sort.collect {|n, mod| mod.to_s }.join("\n\n")
  end

  def self.to_puppetfile(json_data)
    obj = JSON.parse(json_data)
    mods = obj.collect do |name, metadata|
      name = "mod '#{name}',"
      data = metadata.sort.map { |k, v| ":#{k} => '#{v}'" }.join(",\n\  ")
      "#{name}\n  #{data}\n"
    end.join("\n")
    mods
  end

  def mod(name, *args)
    @modules[name] = ControlMod.new(name, args.flatten.first)
  end

  def forge(name, *args)
    # skip this for now
  end

end

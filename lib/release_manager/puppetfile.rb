# frozen_string_literal: true
require_relative 'control_mod'
require_relative 'errors'
require 'json'
require 'release_manager/puppet_module'

class Puppetfile
  attr_accessor :modules, :puppetfile, :data, :base_path, :puppetmodule
  BUMP_TYPES = %w{patch minor major}

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

  def git_command
    "git --work-tree=#{base_path} --git-dir=#{base_path}/.git"
  end

  def commit(message)
    puts `#{git_command} add #{puppetfile}`
    puts `#{git_command} commit -n -m "[ReleaseManager] - #{message}"`
  end

  def current_branch
    `#{git_command} rev-parse --abbrev-ref HEAD`
  end

  def push(remote, branch, force = false)
    opts = force ? '-f' : ''
    `#{git_command} push #{remote} #{branch} #{opts}`
  end

  def data
    unless @data
      @data = File.read(puppetfile)
    end
    @data
  end

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
    mod = modules[mod_name] || modules.find{ |module_name, mod| mod.metadata[:repo] =~ /#{mod_name}/i }
    raise InvalidModuleNameException.new("Invalid module name #{name}, cannot locate in Puppetfile") unless mod
    mod
  end

  def write_version(mod_name, version)
    mod = find_mod(mod_name)
    mod.pin_version(version)
  end

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

  def write_to_file
    File.write(puppetfile, to_s)
  end

  def to_s
    modules.collect {|n, mod| mod.to_s }.join("\n\n")
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

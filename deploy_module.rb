# frozen_string_literal: true
class Puppetfile
  attr_accessor :modules, :puppetfile, :data
  BUMP_TYPES = %w{patch minor major}

  def initialize(puppetfile = 'Puppetfile')
    @puppetfile = puppetfile
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

  def find_mod(name)
    modules[name]
  end

  def bump(mod_name, type = 'patch')
    raise "Invalid type, must be one of #{BUMP_TYPES}" unless BUMP_TYPES.include?(type)
    find_mod(mod_name).send("bump_#{type}_version")
  end

  def to_json(pretty = false)
    if pretty
      JSON.pretty_generate(modules)
    else
      modules.to_json
    end
  end

  def to_puppetfile
    File.write(puppetfile, to_s)
  end

  def to_s
    modules.collect {|n, mod| mod.to_s }.join("\n")
  end

  def self.to_puppetfile(json_data)
    obj = JSON.parse(json_data)
    mods = obj.collect do |name, metadata|
      name = "mod '#{name}',"
      data = metadata.sort.map { |k, v| ":#{k} => '#{v}'" }.join(",\n\  ")
      "#{name}\n  #{data}"
    end.join("\n")
    mods
  end

  def mod(name, *args)
    @modules[name] = PModule.new(name, args.flatten.first)
  end

end

class PModule
  attr_reader :name, :metadata
  attr_accessor :version

  def initialize(name, args)
    @name = name
    @metadata = args
  end

  def to_json(state = nil)
    metadata.to_json(state)
  end

  def to_s
    name_line = "mod '#{name}',"
    data = metadata.map { |k, v| ":#{k} => '#{v}'" }.join(",\n\  ")
    "#{name_line}\n  #{data}"
  end

  def bump_patch_version
    return unless metadata["tag"]
    pieces = metadata["tag"].split('.')
    raise "invalid semver structure #{metadata["tag"]}" if pieces.count != 3
    pieces[2] = pieces[2].next
    pin_version(pieces.join('.'))
  end

  def bump_minor_version
    return unless metadata["tag"]
    pieces = metadata["tag"].split('.')
    raise "invalid semver structure #{metadata["tag"]}" if pieces.count != 3
    pieces[2] = '0'
    pieces[1] = pieces[1].next
    pin_version(pieces.join('.'))
  end

  def bump_major_version
    return unless metadata["tag"]
    pieces = metadata["tag"].split('.')
    raise "invalid semver structure #{metadata["tag"]}" if pieces.count != 3
    pieces[2] = '0'
    pieces[1] = '0'
    pieces[0] = pieces[0].next
    pin_version(pieces.join('.'))
  end

  def version
    metadata["tag"]
  end

  def version=(v)
    metadata["tag"] = v
  end

  def pin_version(v)
    metadata.delete('ref')
    metadata.delete('branch')
    metadata["tag"] = v
  end
end

# get path to puppetfile
def puppetfile_path
  ENV['PUPPET_FILE_PATH'] || File.expand_path("~/repos/r10k-control/Puppetfile")
end

pf = Puppetfile.new(puppetfile_path)

# update puppetfile
# commit puppetfile
# push code to repo
# create MR

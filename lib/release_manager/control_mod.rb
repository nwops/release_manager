class ControlMod
  attr_reader :name, :metadata
  attr_accessor :version

  def initialize(name, args)
    @name = name
    @metadata = args.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
  end

  def git_url
    metadata[:repo]
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
    return unless metadata[:tag]
    pieces = metadata[:tag].split('.')
    raise "invalid semver structure #{metadata[:tag]}" if pieces.count != 3
    pieces[2] = pieces[2].next
    pin_version(pieces.join('.'))
  end

  def bump_minor_version
    return unless metadata[:tag]
    pieces = metadata[:tag].split('.')
    raise "invalid semver structure #{metadata[:tag]}" if pieces.count != 3
    pieces[2] = '0'
    pieces[1] = pieces[1].next
    pin_version(pieces.join('.'))
  end

  def bump_major_version
    return unless metadata[:tag]
    pieces = metadata[:tag].split('.')
    raise "invalid semver structure #{metadata[:tag]}" if pieces.count != 3
    pieces[2] = '0'
    pieces[1] = '0'
    pieces[0] = pieces[0].next
    pin_version(pieces.join('.'))
  end

  def version
    metadata[:tag]
  end

  def version=(v)
    metadata[:tag] = v
  end

  def pin_version(v)
    metadata.delete(:ref)
    metadata.delete(:branch)
    metadata[:tag] = v
  end
end

require 'json'
require_relative 'errors'
require 'release_manager/workflow_action'

class PuppetModule < WorkflowAction
 attr_reader :name, :metadata_file, :mod_path, :version, :upstream
 attr_writer :version, :source
 
 def initialize(mod_path, upstream = nil)
   raise ModNotFoundException if mod_path.nil?
   @mod_path = mod_path
   @upstream = upstream 
   @metadata_file = File.join(mod_path, 'metadata.json')
 end

 def self.check_requirements(path)
   pm = new(path)
   raise InvalidMetadataSource if pm.source !~ /\Agit\@/
   raise UpstreamSourceMatch unless pm.git_upstream_set?
 end

 def name
   namespaced_name.split(/\/|\-/).last
 end
 
 def namespaced_name 
   metadata['name']
 end

 # @returns [Hash] the metadata object as a ruby hash
 def metadata
   unless @metadata
     raise ModNotFoundException unless File.exists?(metadata_file) 
     @metadata ||= JSON.parse(File.read(metadata_file))
   end
   @metadata
 end

 def add_upstream_remote
   if upstream != source
     `#{git_command} remote rm upstream`
   end
   `#{git_command} remote add upstream #{source}`
 end

 def git_upstream_url
   `#{git_command} config --get remote.upstream.url`.chomp
 end

 def git_upstream_set?
    source == git_upstream_url
 end

 def tags
  `#{git_command} tag`.split("\n").map{|v| pad_version_string(v)}
 end

 def source=(s)
   metadata['source'] = s
 end

 def source
   metadata['source']
 end

 def pad_version_string(version_string)
   parts = version_string.split('.').reject {|x| x == '*'}
   while parts.length < 3
     parts << '0'
   end
   parts.join '.'
 end

 def latest_tag
   Gem::Version.new('0.0.12') >= Gem::Version.new('0.0.2')
   v = tags.sort do |a,b|
    Gem::Version.new(a.tr('v', '')) <=> Gem::Version.new(b.tr('v', ''))
   end
   v.last
 end

 # @returns [String] the name of the module found in the metadata file
 def mod_name
   metadata['name']
 end

 def version=(v)
   metadata['version'] = v
 end

 # @returns [String] the version found in the metadata file
 def version
   metadata['version']
 end

 def tag_module
   `git --git-dir=#{mod_path}/.git tag -m 'v#{version}' v#{version}`
 end

 def bump_patch_version
    return unless version
    pieces = version.split('.')
    raise "invalid semver structure #{version}" if pieces.count != 3
    pieces[2] = pieces[2].next
    metadata['version'] = pieces.join('.')
 end

 def bump_minor_version
    return unless version
    pieces = version.split('.')
    raise "invalid semver structure #{version}" if pieces.count != 3
    pieces[2] = '0'
    pieces[1] = pieces[1].next
    metadata['version'] = pieces.join('.')
 end

 def bump_major_version
    return unless version
    pieces = version.split('.')
    raise "invalid semver structure #{version}" if pieces.count != 3
    pieces[2] = '0'
    pieces[1] = '0'
    pieces[0] = pieces[0].next
    metadata['version'] = pieces.join('.')
 end

 def to_s
   JSON.pretty_generate(metadata)
 end

 def r10k_module?
   name =~ /r10k_control/i
 end

 def branch_exists?(name)
   `#{git_command} branch |grep '#{name}$'`
   $?.success?
 end

 def git_command
   @git_command ||= "git --work-tree=#{mod_path} --git-dir=#{mod_path}/.git"
 end

 def upstream
   @upstream ||= git_upstream_url
 end

 # ensures the dev branch has been created and is up to date
 def create_dev_branch
   `#{git_command} fetch upstream`
   raise GitError unless $?.success?
   #puts "#{git_command} checkout -b #{src_branch} upstream/#{src_branch}"
  `#{git_command} checkout -b #{src_branch} upstream/#{src_branch}` unless branch_exists?(src_branch)
   raise GitError unless $?.success?
   # ensure we have updated our local branch
   #puts "#{git_command} checkout #{src_branch}"
  `#{git_command} checkout #{src_branch}`
   raise GitError unless $?.success?
   #puts "#{git_command} rebase upstream/#{src_branch}"
  `#{git_command} rebase upstream/#{src_branch}`
   raise GitError unless $?.success?
 end

 # @returns [String] - the source branch to push to
 # if r10k-control this branch will be dev, otherwise master
 def src_branch
   r10k_module? ? 'dev' : 'master'
 end

 def push
   `#{git_command} push #{source} #{src_branch} --tags`
 end

 def commit_metadata
   to_metadata_file
   `#{git_command} add #{metadata_file}`
   `#{git_command} commit -n -m "[Autobot] - bump version to #{version}"`
 end

 def to_metadata_file
   File.write(metadata_file, to_s)
 end

end

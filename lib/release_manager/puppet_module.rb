require 'json'
require 'release_manager/errors'
require 'release_manager/workflow_action'
require 'release_manager/vcs_manager'
require 'release_manager/git/utilites'
require 'rugged'

class PuppetModule < WorkflowAction
 attr_reader :name, :metadata_file, :path, :version, :upstream, :options
 attr_writer :version, :source

 include ReleaseManager::Git::Utilities
 include ReleaseManager::Logger
 include ReleaseManager::VCSManager

 def initialize(mod_path, options = {})
   raise ModNotFoundException.new("#{mod_path} is not a valid puppet module path") if mod_path.nil?
   @path = mod_path
   @options = options
   @upstream = options[:upstream]
   @metadata_file = File.join(mod_path, 'metadata.json')
 end

 def repo
   @repo ||= Rugged::Repository.new(path)
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
     raise ModNotFoundException.new("#{path} does not contain a metadata file") unless File.exists?(metadata_file)
     @metadata ||= JSON.parse(File.read(metadata_file))
   end
   @metadata
 end

 def already_latest?
   return false unless latest_tag
   up2date?(latest_tag, src_branch)
 end

 def add_upstream_remote
   add_remote(source,'upstream',true )
 end

 def git_upstream_url
   repo.remotes['upstream'].url if remote_exists?('upstream')
 end

 def git_upstream_set?
    source == git_upstream_url
 end

 def tags
   repo.tags.map{|v| pad_version_string(v.name)}
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

 # @return [Array<String>] - returns a array of version strings with the v in the name
 def version_tags
   tags.find_all {|tag| tag =~ /\Av\d/ }
 end

 # @return [String] -  the latest tag in a series of versioned tags
 def latest_tag
   v = version_tags.sort do |a,b|
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

 # @returns [String] the next version based on the release level
 def next_version(level = 'patch')
   return unless version
   pieces = version.split('.')
   raise "invalid semver structure #{version}" if pieces.count != 3

   case level
     when 'major'
       pieces[2] = '0'
       pieces[1] = '0'
       pieces[0] = pieces[0].next
     when 'minor'
       pieces[2] = '0'
       pieces[1] = pieces[1].next
     when 'patch'
       pieces[2] = pieces[2].next
     else
       raise "expected semver release level major, minor or patch"
   end
   pieces.join('.')
 end

 # @param remote [Boolean] - create the tag remotely using the remote VCS
 # @param id [String] - the commit id to tag to
 def tag_module(remote = false, id = nil)
   id ||= repo.head.target_id
   if remote
     # TODO add release_notes as the last argument, currently nil
     # where we get the latest from the changelog
     create_tag(source, "v#{version}", id, "v#{version}", nil)
   else
     create_local_tag("v#{version}", id)
   end
 end

 # Updates the version in memory
 def bump_patch_version
    metadata['version'] = next_version('patch')
 end

 # Updates the version in memory
 def bump_minor_version
    metadata['version'] = next_version('minor')
 end

 # Updates the version in memory
 def bump_major_version
    metadata['version'] = next_version('major')
 end

 def to_s
   JSON.pretty_generate(metadata)
 end

 # @return [Boolean] - true if the module is an r10k-control repository
 def r10k_module?
   mod_name =~ /r10k[-_]?control/i
 end

 def upstream
   @upstream ||= git_upstream_url
 end

 # @param branch [String] -  the name of the source branch to create and rebase from
 # creates a branch and checkouts out the branch with the latest source of the upstream source
 def create_src_branch(branch = src_branch)
   fetch('upstream')
   create_branch(branch, "upstream/#{branch}")
   # ensure we have updated our local branch
   checkout_branch(branch)
   rebase_branch(branch, branch, 'upstream')
 end

 # ensures the dev branch has been created and is up to date
 # @deprecated Use {#create_src_branch} instead of this method which defaults to dev or master branch
 def create_dev_branch
   create_src_branch(src_branch)
 end

 # @returns [String] - the source branch to push to
 # if the user supplied the src_branch we use that otherwise
 # if the module is r10k-control this branch will be dev,
 # if the module is not r10k-control we use master
 def src_branch
   options[:src_branch] || r10k_module? ? 'dev' : 'master'
 end

 # pushes the source
 def push_to_upstream
   push_branch(source, src_branch)
   push_tags(source)
 end

 # @return [String] the oid of the commit that was created
 # @param remote [Boolean] if true creates the commit on the remote repo
 def commit_metadata(remote = false)
   message = "[ReleaseManager] - bump version to #{version}"
   if remote
     actions = [{
       action: 'update',
       file_path: metadata_file.split(repo.workdir).last,
       content: JSON.pretty_generate(metadata)
     }]
     obj = vcs_create_commit(source, src_branch, message, actions)
     obj.id if obj
   else
     to_metadata_file
     add_file(metadata_file)
     create_commit(message)
   end
 end

 # @return [String] the oid of the commit that was created
 def commit_metadata_source(remote = false)
   message = "[ReleaseManager] - change source to #{source}"
   if remote
     actions = [{
       action: 'update',
       file_path: metadata_file.split(repo.workdir).last,
       content: JSON.pretty_generate(metadata)
     }]
     obj = vcs_create_commit(source, src_branch, message, actions)
     obj.id if obj
   else
     to_metadata_file
     add_file(metadata_file)
     create_commit(message)
   end
 end

 def tag_exists?(tag, remote = false)
   if remote
     remote_tag_exists?(source, tag)
   else
     latest_tag == tag
   end
 end

 def to_metadata_file
   logger.info("Writing to file #{metadata_file}")
   File.write(metadata_file, to_s)
 end

 # @return [ControlRepo] - creates a new control repo object and clones the url unless already cloned
 def self.create(path, url, branch = 'master')
   c = PuppetModule.new(path, url)
   c.clone(url, path)
   c
 end

end

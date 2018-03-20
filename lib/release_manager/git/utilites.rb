require 'release_manager/git/credentials'
require 'uri'

module ReleaseManager
  module Git
    STATUSES = [:added, :deleted, :modified, :renamed, :copied, :ignored, :untracked, :typechange]
    module Utilities

      def repo
        @repo ||= Rugged::Repository.new(path)
      end

      # @param [String] remote_name - the name of the remote
      def fetch(remote_name = 'upstream', tags = false)
        remote_name ||= 'upstream'
        return unless remote_exists?(remote_name)
        remote = repo.remotes[remote_name]
        options = {credentials: credentials.call(remote.url)}
        logger.info("Fetching remote #{remote_name} from #{remote.url}")
        options[:certificate_check] = lambda { |valid, host| true } if ENV['GIT_SSL_NO_VERIFY']
        fetch_cli(remote_name) # helps get tags
        remote.fetch(options)
      end

      def transports
        [:ssh, :https].each do |transport|
          unless ::Rugged.features.include?(transport)
            logger.warn("Rugged has been compiled without support for %{transport}; Git repositories will not be reachable via %{transport}.  Try installing libssh-devel") % {transport: transport}
          end
        end
      end

      def credentials
        @credentials ||= ReleaseManager::Git::Credentials.new(nil)
      end

      # @param [String] branch - the name of the branch you want checked out when cloning
      # @param [String] url - the url to clone
      # @return [Rugged::Repository] - the clond repository
      # Clones the url
      # if the clone path already exists, nothing is done
      def clone(url, path)
        if File.exists?(File.join(path, '.git'))
          add_remote(url, 'upstream')
          fetch('upstream')
          repo
        else
          logger.info("Cloning repo with url: #{url} to #{path}")
          r = Rugged::Repository.clone_at(url, path, {
              #progress: lambda { |output| puts output },
              credentials: credentials.call(url)
          })
          r
        end
      end

      # @param [String] url - the url of the remote
      # @param [String] remote_name - the name of the remote
      # @param [Boolean] reset_url - set to true if you wish to reset the remote url
      # @return [Rugged::Remote] a rugged remote object
      def add_remote(url, remote_name = 'upstream', reset_url = false )
        return false unless git_url?(url)
        url = url.gsub('"', '') # remove quotes if url contains quotes
        if remote_exists?(remote_name)
          # ensure the correct url is set
          # this sets a non persistant fetch url
          unless remote_url_matches?(remote_name, url)
            if reset_url
              logger.info("Resetting #{remote_name} remote to #{url} for #{path}")
              repo.remotes.set_url(remote_name,url)
              repo.remotes[remote_name]
            end
          end
        else
          logger.info("Adding #{remote_name} remote to #{url} for #{path}")
          repo.remotes.create(remote_name, url)
        end
      end

      # @param [String] name - the name of the remote
      # @return [Boolean] - return true if the remote name and url are defined in the git repo
      def remote_exists?(name)
        repo.remotes[name]
      end

      # @param [String] name - the name of the remote
      # @param [String] url - the url of the remote
      # @return [Boolean] - true if the url matches a remote url already defined
      def remote_url_matches?(name, url)
        repo.remotes[name].url.eql?(url)
      end

      # @param name [String] - the name of the branch
      # @return [Boolean] - true if the branch exist
      def branch_exist?(name)
        # ensure we have the latest branches
        remote_name, ref = name.split('/', 2)
        if name.include?('/')
          remote_name, ref = name.split('/', 2)
        else
          ref = name
        end
        # check to see if we just needed to fetch the upstreams
        fetch(remote_name) unless (repo.branches.exist?(name) || ref_exists?(name) || tag_exists?(ref))
        repo.branches.exist?(name) || ref_exists?(name) || tag_exists?(ref)
      end

      # we should be creating the branch from upstream
      # @return [Rugged::Branch]
      def create_branch(name, target = 'upstream/master')
        # fetch the remote if defined in the target
        unless branch_exist?(name)
          remote_name, ref = target.split('/', 2)
          fetch(remote_name)
          logger.info("Creating branch: #{name} for #{path} from #{target}")
          found_ref = find_ref(target)
          repo.create_branch(name, found_ref)
        else
          repo.branches[name]
        end
      end

      # deletes the branch with the given name
      # @param [String] name - the name of the branch to delete
      def delete_branch(name)
        repo.branches.delete(name)
        !branch_exist?(name)
      end

      # @param [String] remote_name - the remote name to push the branch to
      def push_branch(remote_name, branch, force = false)
        remote = find_or_create_remote(remote_name)
        b = repo.branches[branch]
        raise InvalidBranchName.new("Branch #{branch} does not exist locally, cannot push") unless b
        refs = [b.canonical_name]
        refs = refs.map { |r| r.prepend('+') } if force
        logger.info("Pushing branch #{branch} to remote #{remote.url}")
        remote.push(refs, credentials: credentials)
      end

      # @return [Array] - returns an array of tag names
      def tags
        repo.tags.map(&:name)
      end

      # @param name [String] - the name of the tag to check for existence
      # @return [Boolean] - return true if the tag exists
      def tag_exists?(name)
       tags.include?(name)
      end

      # push all the tags to the remote
      # @param [String] remote_name - the remote name to push tags to
      def push_tags(remote_name)
        remote = find_or_create_remote(remote_name)
        refs = repo.tags.map(&:canonical_name)
        logger.info("Pushing tags to remote #{remote.url}")
        remote.push(refs, credentials: credentials)
      end

      # @return [String] the name of the current branch
      def current_branch
        repo.head.name.sub(/^refs\/heads\//, '')
      end

      # @param name [String] - the name of the branch
      # @return [Boolean] returns true if the current branch is the name
      def current_branch?(name)
        current_branch != name
      end

      # @param name [String] - the name of the tag
      # @param ref [String] - the ref oid the tag should point to
      # @param message [String] - optional tag message
      def create_local_tag(name, ref, message = nil)
        message ||= name
        logger.info("Creating tag #{name} which points to #{ref}")
        repo.tags.create(name, ref, {:message => message} )
      end

      # @param name [String] - the name of the branch to checkout
      # @return [Rugged::Branch] returns the rugged branch object
      def checkout_branch(name, options = {})
        if current_branch?(name)
          logger.debug("Checking out branch: #{name} for #{path}")
          repo.checkout(name, options)
          logger.debug("Checked out branch: #{current_branch} for #{path}")
        else
          # already checked out
          logger.debug("Currently on branch #{name} for #{path}")
          repo.branches[name]
        end
      end

      # @param [String] remote_name - the remote name
      # @return [Rugged::Remote] the remote object
      # find the remote or create a new remote with the name as source
      def find_or_create_remote(remote_name)
        remote_from_name(remote_name) ||
            remote_from_url(remote_name) ||
            add_remote(remote_name, 'source', true)
      end

      # @param [String] name - the remote name to push the branch to
      # @return [Rugged::Remote] the remote object if found
      # Given the url find the remote with that url
      def remote_from_name(name)
        repo.remotes.find { |r| r.name.eql?(name) } unless git_url?(name)
      end

      # @param [String] url - the remote url to push the branch to
      # @return [Rugged::Remote] the remote object if found
      # Given the url find the remote with that url
      def remote_from_url(url)
        repo.remotes.find { |r| r.url.eql?(url) } if git_url?(url)
      end

      # @param [String] name - the remote name or url to check
      # @return [MatchData] MatchData if the remote name is a url
      # Is the name actually a url?
      def git_url?(name)
        /([A-Za-z0-9]+@|http(|s)\:\/\/)([A-Za-z0-9.]+)(:|\/)([A-Za-z0-9\/]+)(\.git)?/.match(name)
      end

      # @return [String] - the author name found in the config
      def author_name
        repo.config.get('user.name') || Rugged::Config.global.get('user.name') || ENV['GIT_USER_NAME']
      end

      # @return [String] - the author email found in the config
      def author_email
        repo.config.get('user.email') || Rugged::Config.global.get('user.email') || ENV['GIT_USER_EMAIL']
      end

      # @return [Hash] the author information used in a commit message
      def author
        {:email=>author_email, :time=>Time.now, :name=>author_name}
      end

      # @param pathspec Array[String] path specs as strings in an array
      def add_all(pathspec = [])
        index = repo.index
        index.add_all
        index.write
      end

      # @param [String] file - the path to the file you want to add
      def add_file(file)
        logger.debug("Adding file #{file}")
        return add_all if file == '.'
        index = repo.index
        file.slice!(repo.workdir)
        index.add(:path => file, :oid => Rugged::Blob.from_workdir(repo, file), :mode => 0100644, valid: false)
      end

      # @param [String] file - the path to the patch file you want to apply
      def apply_patch(file)
        # TODO: change this to rugged implementation
        empty = File.read(file).length < 1
        logger.info("Applying patch #{file}")
        output = ''
        logger.debug("The patch file is empty for some reason") if empty
        Dir.chdir(path) do
          output = `#{git_command} apply #{file} 2>&1`
        end
        raise PatchError.new(output) unless $?.success?
      end

      # @param [String] - the name of the remote to fetch from
      # @note this is a hack to get around libgit2 inability to get remote tags
      def fetch_cli(remote)
        `#{git_command} fetch #{remote} 2>&1 > /dev/null`
      end

      # [Rugged::Diff] a rugged diff object
      # Not fully tested
      def apply_diff(diff)
        diff.deltas.each do |d|
          case d.status
            when :deleted
              remove_file(d.new_file[:path])
              File.delete(File.join(path, path))
            when :added, :modified
              add_file(d.new_file[:path])
            when :renamed
              remove_file(d.old_file[:path])
              File.delete(File.join(path, path))
              add_file(d.new_file[:path])
            else
              logger.warn("File has a status of #{d.status}")
          end
        end
      end

      def up2date?(src_ref, dst_ref)
        create_diff(src_ref, dst_ref).deltas.count < 1
      end

      # @return [String] the git command with
      def git_command
        @git_command ||= "git --work-tree=#{path} --git-dir=#{repo.path}"
      end

      # @param [String] file - the path to the file you want to remove
      def remove_file(file)
        logger.debug("Removing file #{file}")
        index = repo.index
        File.unlink(file)
        index.remove(file)
      end

      # @param [String] message - the message you want in the commit
      def create_commit(message)
        unless author_name and author_email
          raise GitError.new("Git username and email must be set, current: #{author.inspect}")
        end
        # get the index for this repository
        repo.status { |file, status_data| logger.debug "#{file} has status: #{status_data.inspect}" }
        index = repo.index
        options = {}
        options[:author] = author
        options[:message] = message
        options[:committer] = author
        options[:parents] = repo.empty? ? [] : [repo.head.target].compact
        options[:update_ref] = 'HEAD'
        options[:tree] = index.write_tree
        index.write
        oid = Rugged::Commit.create(repo, options)
        if oid
          logger.info("Created commit #{message}")
          repo.status { |file, status_data| logger.debug "#{file} has status: #{status_data.inspect}" }
        else
          logger.warn("Something went wrong with the commit")
        end
        oid
      end

      # @param [String] message - the message you want in the commit
      # TODO: change this to rugged implementation
      def cli_create_commit(message)
        output = nil
        Dir.chdir(path) do
          output = `#{git_command} commit --message '#{message}' 2>&1`
        end
        if $?.success?
          logger.info("Created commit #{message}")
        else
          if output =~ /nothing\sto\scommit/
            logger.info("Nothing to commit")
          else
            logger.error output
          end
          return false
        end
      end

      # @param [String] branch_name - the branch name you want to update
      # @param [String] target - the target branch you want to rebase against
      # @param [String] remote - the remote name to rebase from, defaults to local
      # TODO: change this to rugged implementation
      def rebase_branch(branch_name, target, remote = nil)
        src = [remote, target].compact.join('/') # produces upstream/master
        Dir.chdir(path) do
          checkout_branch(branch_name)
          logger.info("Rebasing #{branch_name} with #{src}")
          output = `#{git_command} rebase #{src} 2>&1`
          raise GitError.new(output) unless $?.success?
        end
      end

      def cherry_pick(commit)
        return unless commit
        repo.cherrypick(commit)
        logger.info("Cherry picking commit with id: #{commit}")
      end

      # @param src [Rubbed::Object] - the rugged object to compare from
      # @param dst [Rubbed::Object] - the rugged object to compare to
      # @return [Array[String]] the changed files in the commit or all the commits in the diff between src and dst
      def changed_files(src_ref, dst_ref)
        src = repo.lookup(find_ref(src_ref))
        src = src.kind_of?(Rugged::Tag::Annotation) ? src.target : src
        dst = repo.lookup(find_ref(dst_ref))
        dst.diff(src).deltas.map { |d| [d.old_file[:path], d.new_file[:path]] }.flatten.uniq
      end

      # @param oid [String] the oid of the file object
      # @return [String] the contents of the file from the object
      def get_content(oid)
        return nil if oid =~ /0000000000000000000000000000000000000000/
        obj = repo.read(oid)
        obj.data
      end

      # @param src [Rugged::Object] - the rugged object or string to compare from
      # @param dst [Rugged::Object] - the rugged object or string to compare to
      # @return Array[Hash] the changed files in the commit or all the commits in the diff between src and dst
      # with status, old_path, new_path, and content
      # status can be one of: :added, :deleted, :modified, :renamed, :copied, :ignored, :untracked, :typechange
      def create_diff_obj(src, dst)
        diff = create_diff(src, dst)
        diff.deltas.map do |d|
          { old_path: d.old_file[:path], status: d.status,
            new_path: d.new_file[:path], content: get_content(d.new_file[:oid])
          }
        end
      end

      # @param src_ref [Rugged::Object] - the rugged object or string to compare from
      # @param dst_ref [Rugged::Object] - the rugged object or string to compare to
      # @return [Rugged::Diff] a rugged diff object between src and dst
      def create_diff(src_ref, dst_ref)
        logger.debug("Creating a diff between #{dst_ref} and #{src_ref}")
        src = repo.lookup(find_ref(src_ref))
        src = src.kind_of?(Rugged::Tag::Annotation) ? src.target : src
        dst = repo.lookup(find_ref(dst_ref))
        dst = dst.kind_of?(Rugged::Tag::Annotation) ? dst.target : dst
        dst.diff(src)
      end

      # @param sha_or_ref [String] - the name or sha of the ref
      # @return [Boolean] true if the ref exists
      def ref_exists?(sha1_or_ref)
        begin
          find_ref(sha1_or_ref)
        rescue Rugged::ReferenceError => e
          false
        end
      end

      # @param sha_or_ref [String] - the name or sha of the ref
      # @return [String] the oid of the sha or ref
      def find_ref(sha_or_ref)
        case sha_or_ref
          when Rugged::Object
            sha_or_ref.oid
          else
            begin
              repo.rev_parse_oid(sha_or_ref)
            rescue Rugged::ReferenceError => e
              tag = repo.tags.find{|t| t.name == sha_or_ref.split('/').last}
              repo.rev_parse_oid(tag.target.oid) if tag
            end
        end
      end
    end
  end
end

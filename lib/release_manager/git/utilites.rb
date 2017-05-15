require 'release_manager/git/credentials'
require 'uri'

module ReleaseManager
  module Git
    module Utilities

      def repo
        @repo ||= Rugged::Repository.new(path)
      end

      # @param [String] remote_name - the name of the remote
      def fetch(remote_name = 'upstream')
        return unless remote_exists?(remote_name)
        remote = repo.remotes[remote_name]
        logger.info("Fetching remote #{remote_name} from #{remote.url}")
        remote.fetch({
                         #progress: lambda { |output| puts output },
                         credentials: credentials.call(remote.url)
                     })
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
        return unless git_url?(url)
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

      # @param [String] name - the name of the branch
      # @return [Boolean] - true if the branch exist
      def branch_exist?(name)
        repo.branches.exist?(name)
      end

      # we should be creating the branch from upstream
      # @return [Rugged::Branch]
      def create_branch(name, target = 'upstream/master')
        # fetch the remote if defined in the target
        unless branch_exist?(name)
          fetch(target.split('/').first) if target.include?('/')
          logger.info("Creating branch: #{name} for #{path}")
          repo.create_branch(name, target)
        else
          repo.branches[name]
        end
      end

      # deletes the branch with the given name
      # @param [String] name - the name of the branch to delete
      def delete_branch(name)
        repo.branches.delete(name)
      end

      # @param [String] remote_name - the remote name to push the branch to
      def push_branch(remote_name, branch)
        remote = find_or_create_remote(remote_name)
        refs = [repo.branches[branch].canonical_name]
        logger.info("Pushing branch #{branch} to remote #{remote.url}")
        remote.push(refs, credentials: credentials)
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

      def checkout_branch(name)
        if current_branch != name
          logger.info("Checking out branch: #{name} for #{path}")
          repo.checkout(name)
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
        /((git|ssh|http(s)?)|(git@[\w\.]+))(:(\/\/)?)([\w\.@\:\/\-~]+)(\.git)(\/)?/.match(name)
      end

      # @return [String] - the author name found in the config
      def author_name
        repo.config.get('user.name') || Rugged::Config.global.get('user.name')
      end

      # @return [String] - the author email found in the config
      def author_email
        repo.config.get('user.email') || Rugged::Config.global.get('user.email')
      end

      # @return [Hash] the author information used in a commit message
      def author
        {:email=>author_email, :time=>Time.now, :name=>author_name}
      end

      # @param [String] file - the path to the file you want to add
      def add_file(file)
        return unless File.exists?(file)
        index = repo.index
        file.slice!(repo.workdir)
        index.add(:path => file, :oid => Rugged::Blob.from_workdir(repo, file), :mode => 0100644)
      end

      # @param [String] file - the path to the file you want to remove
      def remove_file(file)
        index = repo.index
        File.unlink(file)
        index.remove(file)
      end

      # @param [String] message - the message you want in the commit
      def create_commit(message)
        # get the index for this repository
        index = repo.index
        commit_tree = repo.lookup(repo.index.write_tree)
        oid = Rugged::Commit.create(repo,
                              :author => author,
                              :message => message,
                              :committer => author,
                              :parents => [repo.head.target],
                              :tree => commit_tree,
                              :update_ref => 'HEAD')
        logger.info("Created commit #{oid} with #{message}")
        repo.index.write
        oid
      end

      # @return [String] the current branch name
      def current_branch
        repo.head.name.sub(/^refs\/heads\//, '')
      end

      def cherry_pick(commit)
        return unless commit
        repo.cherrypick(commit)
        logger.info("Cherry picking commit with id: #{commit}")
      end

    end
  end
end

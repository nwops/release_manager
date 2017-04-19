require 'release_manager/git/credentials'

module ReleaseManager
  module Git
    module Utilities

      def fetch(remote_name = 'upstream')
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

      def add_remote(url, remote_name = 'upstream' )
        if remote_exists?(remote_name)
          # ensure the correct url is set
          # this sets a non persistant fetch url
          unless remote_url_matches?(remote_name, url)
            logger.info("Resetting #{remote_name} remote to #{url} for #{path}")
            repo.remotes.set_url(remote_name,url)
          end
        else
          logger.info("Adding #{remote_name} remote to #{url} for #{path}")
          repo.remotes.create(remote_name, url)
        end
      end

      # @return [Boolean] - return true if the remote name and url are defined in the git repo
      def remote_exists?(name)
        repo.remotes[name]
      end

      def remote_url_matches?(name, url)
        repo.remotes[name].url.eql?(url)
      end

      def branch_exist?(name)
        repo.branches.exist?(name)
      end

      # we should be creating the branch from upstream
      # @return [Rugged::Branch]
      def create_branch(name, target = 'upstream/master')
        unless branch_exist?(name)
          logger.info("Creating branch: #{name} for #{path}")
          repo.create_branch(name, target)
        else
          repo.branches[name]
        end
      end

      # deletes the branch with the given name
      def delete_branch(name)
        repo.branches.delete(name)
      end

      # @param [String] remote_name - the remote name to push the branch to
      def push_branch(remote_name, branch)
        remote = repo.remotes[remote_name]
        refs = [repo.branches[branch].canonical_name]
        logger.info("Pushing branch #{branch} to remote #{remote.url}")
        remote.push(refs, credentials: credentials)
      end

      # push all the tags to the remote
      # @param [String] remote_name - the remote name to push tags to
      def push_tags(remote_name)
        remote = repo.remotes[remote_name]
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

    end
  end
end

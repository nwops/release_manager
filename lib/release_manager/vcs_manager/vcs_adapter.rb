require 'release_manager/logger'
require 'release_manager/errors'

module ReleaseManager
  module VCSManager
    class VcsAdapter
      include ReleaseManager::Logger

      def self.create
        raise NotImplementedError
      end

      def add_ssh_key(public_key)
        raise NotImplementedError
      end

      def add_permission(user, repo)
        raise NotImplementedError
      end

      def create_repo_fork(url, options = {} )
        raise NotImplementedError
      end

      def swap_namespace(url, namespace = nil)
        raise NotImplementedError
      end

      def clone_repo(mod_name, url)
        raise NotImplementedError
      end

      def create_repo_branch(repo_id, branch_name)
        raise NotImplementedError
      end

      def repo_exists?(url)
        raise NotImplementedError
      end

      def repo_id(url)
        raise NotImplementedError
      end

      # @param [String] url - a git url
      # @param  [String]  tag_name The name of the new tag.
      # @param  [String]  ref The ref (commit sha, branch name, or another tag) the tag will point to.
      # @param  [String]  message Optional message for tag, creates annotated tag if specified.
      # @param  [String]  description Optional release notes for tag.
      # @return [Gitlab::ObjectifiedHash]
      def create_tag(url, tag_name, ref, message = nil, description = nil)
        raise NotImplementedError
      end

      # Creates a single commit with one or more changes
      #
      # @example
      # create_commit(2726132, 'master', 'refactors everything', [{action: 'create', file_path: '/foo.txt', content: 'bar'}])
      # create_commit(2726132, 'master', 'refactors everything', [{action: 'delete', file_path: '/foo.txt'}])
      #
      # @param [String] url - a git url
      # @param [String] branch the branch name you wish to commit to
      # @param [String] message the commit message
      # @param [Array[Hash]] An array of action hashes to commit as a batch. See the next table for what attributes it can take.
      # @option options [String] :author_email the email address of the author
      # @option options [String] :author_name the name of the author
      # @return [Gitlab::ObjectifiedHash] hash of commit related data
      def vcs_create_commit(url, branch, message, actions, options={})
        raise NotImplementedError
      end
    end
  end
end
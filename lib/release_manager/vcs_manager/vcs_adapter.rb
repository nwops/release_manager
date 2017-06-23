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
    end
  end
end
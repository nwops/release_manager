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
    end
  end
end
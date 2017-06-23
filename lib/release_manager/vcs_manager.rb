require 'release_manager/vcs_manager/gitlab_adapter'
require 'forwardable'
module ReleaseManager
  module VCSManager
    extend Forwardable

    def_delegators :vcs, :add_ssh_key, :add_permission, :create_repo_fork, :swap_namespace,
                   :clone_repo, :create_repo_branch, :repo_exists?, :repo_id, :add_permissions

    def vcs
      raise NotImplementedError
    end

    def self.default_instance
      ReleaseManager::VCSManager::GitlabAdapter.create
    end

    def self.adapter_types
      [:gitlab]
    end

    def self.adapter_instance(type)
      case type
      when :gitlab
        ReleaseManager::VCSManager::GitlabAdapter.create
      else
        default_instance
      end
    end
  end
end

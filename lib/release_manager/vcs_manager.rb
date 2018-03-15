require 'release_manager/vcs_manager/gitlab_adapter'
require 'forwardable'
module ReleaseManager
  module VCSManager
    extend Forwardable
    attr_accessor :vcs
    def_delegators :vcs, :add_ssh_key, :add_permission, :create_repo_fork, :swap_namespace, :create_tag,
                   :clone_repo, :create_repo_branch, :repo_exists?, :repo_id, :add_permissions, :validate_authorization,
                   :vcs_create_commit, :create_merge_request, :diff_2_commit, :vcs_create_branch, :rebase_mr,
                   :remote_tags, :remote_tag_names, :remote_tag_exists?

    def vcs
      @vcs ||= ReleaseManager::VCSManager.default_instance
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

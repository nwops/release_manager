require 'release_manager/vcs_manager/gitlab_adapter'

module ReleaseManager
  module VCSManager
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

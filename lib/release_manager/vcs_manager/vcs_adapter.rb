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
      # @param  [String]  name The name of the new branch.
      # @param  [String]  ref The ref (commit sha, branch name, or another tag) the tag will point to.
      def vcs_create_branch(url, name, ref)
        raise NotImplementedError
      end

      # @param [String] url - a git url
      # @param  [String]  mr_id The id of the merge request
      def rebase_mr(url, mr_id)
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

      # Creates a merge request.
      #
      # @example
      #   create_merge_request(5, 'New merge request',
      #     { source_branch: 'source_branch', target_branch: 'target_branch' })
      #   create_merge_request(5, 'New merge request',
      #     { source_branch: 'source_branch', target_branch: 'target_branch', assignee_id: 42 })
      #
      # @param  [Integer, String] project The ID or name of a project.
      # @param  [String] title The title of a merge request.
      # @param  [Hash] options A customizable set of options.
      # @option options [String] :source_branch (required) The source branch name.
      # @option options [String] :target_branch (required) The target branch name.
      # @option options [Integer] :assignee_id (optional) The ID of a user to assign merge request.
      # @option options [Integer] :target_project_id (optional) The target project ID.
      # @return [Gitlab::ObjectifiedHash] Information about created merge request.
      def create_merge_request(project, title, options={})
        raise NotImplementedError
      end

      # @param Array[Hash] the changed files in the commit or all the commits in the diff between src and dst
      # @return Array[Hash]
      def diff_2_commit(diff_obj)
        raise NotImplementedError
      end

      def remote_tags(url)
        raise NotImplementedError
      end

      def remote_tag_names(url)
        raise NotImplementedError
      end

      def remote_tag_exists?(url, tag)
        raise NotImplementedError
      end

    end
  end
end
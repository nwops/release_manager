require 'release_manager/vcs_manager/vcs_adapter'
require 'gitlab'
module ReleaseManager
  module VCSManager
    class GitlabAdapter < ReleaseManager::VCSManager::VcsAdapter
      attr_reader :client

      def initialize
        @client = Gitlab.client
      end

      # creates an instance of the gitlab adapter
      def self.create
        new
      end

      # adds the ssh key to the user of the token
      def add_ssh_key(public_key_filename = nil)
        public_key_filename ||= File.expand_path(File.join(ENV['HOME'], '.ssh', 'id_rsa.pub'))
        title = "#{ENV['USER']}@#{ENV['HOST']}"
        raise InvalidSshkey.new("Ssh key does not exist #{public_key_filename}") unless File.exist?(public_key_filename)
        begin
          client.create_ssh_key(title, File.read(public_key_filename))
          logger.info("Adding ssh key #{public_key_filename} to gitlab")
        rescue Gitlab::Error::BadRequest => e
          # if the key is already added no need to do anything else
          return unless e.response_status == 400
        end
      end

      def project_name(project_id)
        client.projects(project_id)
      end

      # https://docs.gitlab.com/ee/api/members.html
      def add_permission(username, project_id, access_level = 20)
        begin
          project_name = client.project(project_id).path_with_namespace
          user = client.user_search(username).find{|u| u.username == username}
          unless user
            logger.warn("No user found for #{username}")
            return
          end
          unless check_access?(username, project_id, access_level)
            logger.info("Adding member #{username} to project #{project_name}")
            client.add_team_member(project_id, user.id, access_level)
          end
        rescue Gitlab::Error::BadRequest => e
          # if the key is already added no need to do anything else
          logger.warn(e.message)
        end
      end

      def check_access?(username, project_id, access_level)
        client.team_members(project_id).find { |user| user.username == username && user.access_level == access_level}
      end

      # https://docs.gitlab.com/ee/api/members.html
      def add_permissions(project_id, user_ids = [], access_level = 20)
        user_ids ||= []  # default to empty if nil
        user_ids.map {|id| add_permission(id, project_id, access_level)}
      end

      # @return String - the branch name that was created
      def create_repo_branch(repo_id, branch_name)
        Gitlab.repo_create_branch(repo_id, branch_name)
      end

      #TODO move this to the git utilities?
      def clone_repo(branch_name, mod_name, url, repos_dir)
        path = File.join(repos_dir, mod_name)
        Rugged::Repository.clone_at(url, path, checkout_branch: branch_name)
      end

      # replaces namespace from the url with the supplied or default namespace
      def swap_namespace(url, namespace = nil)
        url.gsub(/\:([\w-]+)\//, ":#{namespace || Gitlab.user.username}/")
      end

      # @return [Gitlab::ObjectifiedHash] Information about the forked project
      # @param [ControlMod] the module you want to fork
      def create_repo_fork(url, options = {} )
        new_url = swap_namespace(url, options[:namespace])
        repo = repo_exists?(new_url)
        unless repo
          upstream_repo_id = repo_id(url)
          logger.info("Forking project from #{url} to #{new_url}")
          repo = Gitlab.create_fork(upstream_repo_id)
          # gitlab lies about having completed the forking process, so lets sleep until it is actually done
          loop do
            sleep(1)
            break if repo_exists?(repo.ssh_url_to_repo)
          end
        end
        add_permissions(repo.id, options[:default_members])
        repo
      end

      # @param [String] url - the git url of the repository
      # @return [Boolean] returns the project object (true) if found, false otherwise
      def repo_exists?(url)
        upstream_repo_id = repo_id(url)
        begin
          Gitlab.project(upstream_repo_id)
        rescue
          false
        end
      end

      # @param [String] url - a git url
      # @return [String] a string representing the project id from gitlab
      # gets the project id from gitlab using the remote API
      def repo_id(url)
        # ie. git@server:namespace/project.git
        proj = url.match(/:(.*\/.*)\.git/)
        raise RepoNotFound unless proj
        # the gitlab api is supposed to encode the slash, but currently that doesn't seem to work
        proj[1].gsub('/', '%2F')
      end

      # @return String - the branch name that was created
      def create_repo_branch(repo_id, branch_name)
        Gitlab.repo_create_branch(repo_id, branch_name)
      end

      def clone_repo(mod_name, url)
        path = File.join(repos_dir, mod_name)
        Rugged::Repository.clone_at(url, path, checkout_branch: name)
      end
    end
  end
end
require 'release_manager/sandbox'
require 'release_manager'
module ReleaseManager
  class SandboxCreateCli

    def self.gitlab_server
     ReleaseManager.gitlab_server
    end

    def self.run
      options = {}
      OptionParser.new do |opts|
        opts.program_name = 'sandbox-create'
        opts.version = ReleaseManager::VERSION
        opts.on_head(<<-EOF

Summary: Creates a new r10k sandbox by forking and creating a new branch on r10k-control,
         creates a fork and branch for each module passed in, adds the upstream remote
         for each module, updates the r10k-control Puppetfile to use those forks and branches
         and pushes the branch to the upstream r10k-control.


Note: If you already have any of these modules cloned, this script will attempt to update those modules
      using git fetch and git checkout -b sandbox_name upstream/master.  So this should not destroy anything.

Configuration:

This script uses the following environment variables to automatically set some options, please ensure 
they exist in your shell environment.  You can set an environment variable in the shell or define 
in your shell startup files.

Shell:  export VARIABLE_NAME=value

R10K_REPO_URL            - The git repo url to r10k-control (ie. git@gitlab.com:devops/r10k-control.git)
GITLAB_API_ENDPOINT      - The api path to the gitlab server  (ie. https://gitlab_server/api/v4)
                           replace gitlab_server with your server hostname
GITLAB_API_PRIVATE_TOKEN - The gitlab user api token.  
                           You can get a token here (#{gitlab_server}/profile/personal_access_tokens, 
                           Ensure api box is checked.
DEFAULT_MODULES          - The default set of modules to fork use when 
                           a sandbox (ie. export DEFAULT_MODULES='hieradata, roles')

DEFAULT_MEMBERS          - The default members each forked project should add permissions
                           to ( ie, DEFAULT_MEMBERS='ci_runner,r10k_user' )

If your gitlab server has a invalid certificate you can set the following variable to "fix" that trust issue.
export GITLAB_API_HTTPARTY_OPTIONS="{verify: false}"

Examples:
  #{opts.program_name} -n my_sandbox -m "roles,profiles,developer" 
  #{opts.program_name} -n my_sandbox -m "roles,profiles,developer" --members="p1dksk2,devops,ci_runner"
  #{opts.program_name} -n my_sandbox -s "upstream/v0.5.0" 

Options:
        EOF
        )
        opts.on('--members DEFAULT_MEMBERS', "A comman seperated list of members to add to forked projects") do |m|
          options[:default_members] = m.split(',').map(&:strip)
        end
        opts.on('-n', "--name NAME", "The name of your sandbox") do |n|
          options[:sandbox_name] = n
        end
        opts.on('-s', "--src-target REMOTE/REF", "The source of the target to create your sandbox from, defaults to upstream/dev") do |n|
          options[:src_target] = n
        end
        opts.on('--control-url R10K_REPO_URL', "git url to the r10k-control repo, defaults to R10K_CONTROL_URL env variable") do |r|
          options[:r10k_repo_url] = r
        end
        opts.on('-m', '--modules MODULES', "A comma separated list of modules names from the Puppetfile to fork and branch") do |c|
          options[:modules] = c.split(',').map(&:strip)
        end
        opts.on('-r', '--repos-dir [REPOS_PATH]', "The repos path to clone modules to. " +
            "Defaults to: #{File.expand_path(File.join(ENV['HOME'], 'repos'))}") do |c|
          options[:repos_path] = c
        end
        opts.on('-c', '--control-dir [CONTROL_DIR]', "The r10k-control repo path. " +
            "Defaults to: #{File.expand_path(File.join(ENV['HOME'], 'repos', 'r10k-control'))}") do |c|
          options[:r10k_repo_path] = c
        end
        opts.on('--verbose', "Extra logging") do |c|
          options[:verbose] = c
        end
      end.parse!
      unless ENV['GITLAB_API_ENDPOINT']
        puts "Please set the GITLAB_API_ENDPOINT environment variable".fatal
        puts "Example: export GITLAB_API_ENDPOINT=https://gitlab.com/api/v4".fatal
        exit 1
      end

      unless ENV['GITLAB_API_PRIVATE_TOKEN']
        puts "Please set the GITLAB_API_PRIVATE_TOKEN environment variable".fatal
        puts "Example: export GITLAB_API_PRIVATE_TOKEN=kdii2ljljijsldjfoa".fatal
        exit 1
      end

      options[:modules] = add_defaults(:modules, options)
      options[:default_members] = add_defaults(:default_members, options)

      options[:r10k_repo_path] ||= File.expand_path(File.join(ENV['HOME'], 'repos', 'r10k-control'))
      options[:repos_path] ||= File.expand_path(File.join(ENV['HOME'], 'repos'))
      options[:r10k_repo_url] ||= ENV['R10K_REPO_URL']

      options[:src_target] ||= 'upstream/dev'
      if options[:src_target].split("/").count < 2
        puts "Please use a source target that conforms to the remote/ref pattern".fatal
        exit 1
      end
      unless options[:r10k_repo_url]
        puts "Please set the R10K_REPO_URL environment variable or use the --control-url option".fatal
        puts "Example: export R10K_REPO_URL='git@gitlab.com:devops/r10k-control.git'".fatal
        exit 1
      end
      unless options[:sandbox_name]
        puts "If you don't name your sandbox, you will not have anywhere to play".fatal
        puts "Example: sandbox-create -n my_sandbox"
        exit 1
      end
      unless options[:sandbox_name].length > 5
        puts "Your sandbox name must be at least 6 characters long".fatal
        puts "Example: sandbox-create -n my_sandbox"
        exit 1
      end
      # check options to ensure all values are present
      begin
        ReleaseManager::VCSManager.default_instance.validate_authorization
        s = Sandbox.create(options[:sandbox_name], options)
      rescue InvalidToken => e
        puts e.message.fatal
        puts "Please update your Gitlab API token as it may be expired or incorrect".fatal
        exit 1 
      end
    end

    def self.add_defaults(key, options)
      if key == :modules
        defaults = (ENV['DEFAULT_MODULES'] || '').split(',').map(&:strip)
        ( options[:modules].to_a + defaults ).uniq
      elsif key == :default_members
        defaults = (ENV['DEFAULT_MEMBERS'] || '').split(',').map(&:strip)
        ( options[:default_members].to_a + defaults ).uniq
      end
    end
  end
end

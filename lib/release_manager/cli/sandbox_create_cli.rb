require 'release_manager/sandbox'

module ReleaseManager
  class SandboxCreateCli
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

Example: #{opts.program_name} -n my_sandbox -m "roles,profiles,developer" -t 3isdfasjio23923
Example: #{opts.program_name} -n my_sandbox -m "roles,profiles,developer" --members="p1dksk2, p2ksdafs,devops,ci_runner" -t 3isdfasjio23923


Note: If you already have any of these modules cloned, this script will attempt to update those modules
      using git fetch and git checkout -b sandbox_name upstream/master.  So this should not destroy anything.

        EOF
        )
        opts.on('--members DEFAULT_MEMBERS', "A comman seperated list of members to add to forked projects") do |m|
          options[:default_members] = m.split(',').map(&:strip)
        end
        opts.on('-n', "--name NAME", "The name of your sandbox") do |n|
          options[:sandbox_name] = n
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
        puts "Example: export GITLAB_API_ENDPOINT=https://gitlab.com/api/v3".fatal
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

      unless options[:r10k_repo_url]
        puts "Please set the R10K_REPO_URL environment variable or use the --control-url option".fatal
        puts "Example: export R10K_REPO_URL='git@gitlab.com/devops/r10k-control.git'".fatal
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

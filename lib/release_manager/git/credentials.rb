require 'rugged'
require 'release_manager/logger'
require 'io/console'
# Generate credentials for secured remote connections.
module ReleaseManager
  module Git
    class Credentials
      include ReleaseManager::Logger

      # @param repository [Rugged::BaseRepository]
      def initialize(repository = nil)
        @repository = repository
        @called = 0
      end

      def needs_auth?(url)
        url =~ /\Agit@/
      end

      def call(url, username_from_url = 'git', allowed_types = [:ssh_key])
        @called += 1
        # Break out of infinite HTTP auth retry loop introduced in libgit2/rugged 0.24.0, libssh
        # auth seems to already abort after ~50 attempts.
        if @called > 50
          raise Exception.new("Authentication failed for Git remote %{url}.") % {url: url.inspect}
        end
        if allowed_types.include?(:ssh_key)
          # should also check to see if process is still alive
          begin
            if ENV['SSH_AUTH_SOCK'] or (ENV['SSH_AGENT_PID'] and Process.getpgid( ENV['SSH_AGENT_PID'].to_i ))
              ssh_agent_credentials
            else
              logger.warn("Could not find ssh-agent running, falling back to ssh key")
              ssh_key_credentials
            end
          rescue Errno::ESRCH
            ssh_key_credentials
          end
        else
          default_credentials
        end
      end

      def prompt_for_password
        print "Enter password for #{global_private_key}: "
        STDIN.noecho(&:gets).chomp
      end

      # this assumes the user has the private key in their home folder
      # we should be smarter about getting this, maybe consulting ssh
      # directory to find out which key is for the host if using an ssh config file
      # additionally if the key is password protected how do we prompt for the password?
      def global_private_key
        unless @global_private_key
          @global_private_key = ENV['SSH_PRIVATE_KEY'] || File.expand_path(File.join(ENV['HOME'], '.ssh', 'id_rsa'))
          logger.info("Using ssh private key #{@global_private_key}")
        end
        @global_private_key
      end

      def global_public_key
        unless @global_public_key
          @global_public_key = ENV['SSH_PUBLIC_KEY'] || File.expand_path(File.join(ENV['HOME'], '.ssh', 'id_rsa.pub'))
          logger.info("Using ssh public key #{@global_public_key}")
        end
        @global_public_key
      end

      # SSH_AGENT_SOCK  must be set
      def ssh_agent_credentials
        Rugged::Credentials::SshKeyFromAgent.new(username: git_username)
      end

      # this method does currently now work
      def ssh_key_credentials(url = nil)
        logger.error("Must use ssh-agent, please run ssh-agent zsh, then ssh-add to load your ssh key")
        exit 1
        unless File.readable?(global_private_key)
          raise Exception.new("Unable to use SSH key auth for %{url}: private key %{private_key} is missing or unreadable" % {url: url.inspect, private_key: global_private_key.inspect} )
        end
        Rugged::Credentials::SshKey.new(:username => git_username,
                                        :privatekey => global_private_key,
                                        :publickey => global_public_key,
                                        :passphrase => prompt_for_password)
      end

      def default_credentials
        Rugged::Credentials::Default.new
      end

      def git_username
        'git'
      end

    end
  end
end


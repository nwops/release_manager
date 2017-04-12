require 'release_manager/module_deployer'
require 'optparse'
require 'release_manager/version'
module ReleaseManager
  class DeployModCli
    def self.run
      options = {}
      OptionParser.new do |opts|
        opts.program_name = 'deploy-mod'
        opts.version = ReleaseManager::VERSION
        opts.on_head(<<-EOF
    
    Summary: Gets the version of your module found in the metadata
             and populates the r10k-control Puppetfile with the updated
             tag version. Revmoes any branch or ref reference and replaces
             with tag.  Currently it is up to you to commit and push the Puppetfile change.

        EOF
        )
        opts.on('-p', "--puppetfile [PUPPETFILE]", 'Path to R10k Puppetfile, defaults to ~/repos/r10k-control/Puppetfile') do |p|
          options[:puppetfile] = p
        end
        opts.on('-m', '--modulepath [MODULEPATH]', "Path to to module, defaults to: #{Dir.getwd}") do |p|
          options[:modulepath] = p
        end
        opts.on('-c', '--commit', 'Optionally, Commit the Puppetfile change') do |p|
          options[:commit] = p
        end
        # removing this option as it seems a little dangerous for now
        # opts.on('-u', '--push', 'Optionally, Push the changes to the remote') do |p|
        #   options[:push] = p
        # end
        # opts.on('-r', '--remote REMOTE', 'Optionally, specify a remote name or url to push changes to') do |p|
        #   options[:remote] = p
        # end
        opts.on('-d', 'Perform a dry run without making changes') do |p|
          options[:dry_run] = p
        end
      end.parse!
      m = ModuleDeployer.new(options)
      m.run
    end
  end
end

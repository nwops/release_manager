require 'release_manager/r10k_deployer'
require 'optparse'
require 'release_manager/version'
module ReleaseManager
  class DeployR10kCli

    def self.puppetfile_path
      ENV['PUPPET_FILE_PATH'] || File.join(File.expand_path(Dir.pwd), 'Puppetfile')
    end

    def self.validate(options)
      if options[:src_ref].nil? or options[:dest_ref].nil?
        puts "You must supply --source and --dest arguments".red
        puts @o
        exit 1
      end

    end

    def self.run
      options = {}
      @o = OptionParser.new do |opts|
        opts.program_name = 'deploy-r10k'
        opts.version = ReleaseManager::VERSION
        opts.on_head(<<-EOF
    
Summary: Deploys the source ref into the dest branch by diffing the two and applying the diff.  Generates a merge 
         request after committing the changes to the dest branch.

   1. fetches the latest code
   2. creates the necessary remotes
   3. Forks project
   4. creates new branch 
   5. creates diff and applies diff to new branch
   6. push branch and create merge request

   Examples:
      deploy-r10k dev qa
      deploy-r10k -s dev -d qa
      deploy-r10k -p ~/repos/r10k-control -s dev -d qa


        EOF
        )
        opts.on('-p', "--puppetfile [PUPPETFILE]", "Path to R10k Puppetfile, defaults to #{puppetfile_path}") do |p|
          options[:puppetfile] = File.expand_path(p)
        end
        opts.on('-s', "--source [SRC_REF]", "The source ref or branch you want to deploy") do |p|
          options[:src_ref] = p
        end
        opts.on('-d', "--dest [DEST_BRANCH]", "The destination branch you want to deploy to") do |p|
          options[:dest_ref] = p
        end
      end
      @o.parse!
      options[:puppetfile] = options[:puppetfile] || puppetfile_path
      options[:src_ref] ||= ARGV[0]
      options[:dest_ref] ||= ARGV[1]
      validate(options)
      path = File.dirname(options[:puppetfile])
      R10kDeployer.run(path, options)
    end
  end
end

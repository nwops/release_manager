require 'optparse'
require 'release_manager/version'
require 'release_manager/changelog'
module ReleaseManager
  class BumpChangelogCli

    def self.run
      options = {}
      OptionParser.new do |opts|
        opts.program_name = 'bump_changelog'
        opts.version = ReleaseManager::VERSION
        opts.on_head(<<-EOF
  
  Summary: updates the changelog.md file with the new
           version by reading the metadata.json file

        EOF
        )
        opts.on("-c", "--[no-]commit", "Commit the updated changelog") do |c|
          options[:commit] = c
        end
        opts.on("-f", "--changelog FILE", "Path to the changelog file") do |c|
          options[:file] = c
        end
      end.parse!
      unless options[:file]
        puts "Must supply --changelog FILE"
        exit 1
      end
      module_path = File.dirname(options[:file])
      puppet_module = PuppetModule.new(module_path)
      log = Changelog.new(module_path, puppet_module.version, options)
      log.run
    end
  end
end

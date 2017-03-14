#!/usr/bin/env ruby
#
#
#Author: Corey Osman
#Purpose: updates the changelog.md file with the new version by reading the metadata.json file
#Usage: ./bump_log.rb [CHANGELOG.md]
#
require 'json'
require 'optparse'
require_relative 'puppet_module'

class Changelog
  attr_reader :root_dir, :version, :options

  def initialize(module_path, version, options = {})
    @options = options
    @root_dir = module_path
    @version = version
  end

  def run
    # write the new changelog unless it does not need updating
    if already_released? 
      puts "Fail: Version #{version} had already been released, did you bump the version?".red
      exit 1
    else
      File.write(changelog_file, new_content) 
      create_commit if options[:commit] 
      puts "Success: The changelog has been updated to version #{version}".green
    end
  end

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

  # @returns [String] the full path to the change log file
  def changelog_file
    file = options[:file] || File.join(root_dir, 'CHANGELOG.md')
    unless File.exists?(file)
      puts "#{file} does not exist".red
      exit 1 
    end
    file
  end

  # @returns [Array[String]]
  def changelog_lines
     @changelog_lines ||= File.readlines(changelog_file)
  end

  # @returns [Integer] line number of where the word unreleased is located
  def unreleased_index 
    changelog_lines.each_index.find {|index| changelog_lines[index] =~ /\A\s*\#{2}\s*Unreleased/i }
  end

  # @returns [Boolean]  returns true if the Changelog has already released this version
  def already_released?
    changelog_lines.each_index.find {|index| changelog_lines[index] =~ /\A\s*\#{2}\s*Version #{version}/i }
  end

  # @returns [Array[String]] - inserts the version header in the change log and returns the entire array of lines
  def update_unreleased
    time = Time.now.strftime("%B %d, %Y")
    changelog_lines.insert(unreleased_index + 1, "\n## Version #{version}\nReleased: #{time}\n\n") 
  end

  # @returns [String] the string representation of the update Changelog file
  def new_content
    update_unreleased.join
  end

  def git_command
    "git --git-dir=#{root_dir}/.git"
  end

  def create_commit
    `#{git_command} add #{changelog_file}`
    puts `#{git_command} commit -m "[Autobot] - bump changelog to version #{version}"`
  end
end


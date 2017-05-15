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
require 'release_manager/workflow_action'

class Changelog < WorkflowAction
  attr_reader :root_dir, :version, :options

  include ReleaseManager::Git::Utilities
  include ReleaseManager::Logger

  def initialize(module_path, version, options = {})
    @options = options
    @root_dir = module_path
    @version = version
  end

  def create_changelog_file
    return if File.exists?(changelog_file)
    contents = "# Module Name\n\n## Unreleased\n"
    File.write(changelog_file, contents)
    logger.info("Creating initial changelog file")
    commit_changelog("[ReleaseManager] - create empty changelog")
  end

  def path
    @root_dir
  end

  def run
    create_changelog_file
    # write the new changelog unless it does not need updating
    if already_released? 
      logger.fatal "Version #{version} had already been released, did you bump the version manually?"
      exit 1
    else
      File.write(changelog_file, new_content)
      commit_changelog if options[:commit]
      logger.info "The changelog has been updated to version #{version}"
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
    options[:file] || File.join(root_dir, 'CHANGELOG.md')
  end

  # @returns [Array[String]]
  def changelog_lines
    @changelog_lines ||= File.readlines(changelog_file)
  end

  # @returns [Integer] line number of where the word unreleased is located
  def unreleased_index
    begin
      linenum = changelog_lines.each_index.find {|index| changelog_lines[index] =~ /\A\s*\#{2}\s*Unreleased/i }
    rescue ArgumentError => e
      logger.fatal "Error with CHANGELOG.md #{e.message}"
      exit 1
    end
    raise NoUnreleasedLine unless linenum
    linenum
  end

  # @returns [Boolean]  returns true if the Changelog has already released this version
  def already_released?
    !!changelog_lines.each_index.find {|index| changelog_lines[index] =~ /\A\s*\#{2}\s*Version #{version}/i }
  end

  # @returns [Array[String]] - inserts the version header in the change log and returns the entire array of lines
  def update_unreleased
    time = Time.now.strftime("%B %d, %Y")
    changelog_lines.insert(unreleased_index + 1, "\n## Version #{version}\nReleased: #{time}\n")
  end

  # @returns [String] the string representation of the update Changelog file
  def new_content
    update_unreleased.join
  end

  # @return [String] the oid of the commit that was created
  def commit_changelog(msg = nil)
    add_file(changelog_file)
    message = msg || "[ReleaseManager] - bump changelog to version #{version}"
    create_commit(message)
  end

  # checks to make sure the unreleased line is valid, and the file exists
  def self.check_requirements(path)
    log = new(path, nil)
    log.unreleased_index if File.exists?(log.changelog_file)
  end
end


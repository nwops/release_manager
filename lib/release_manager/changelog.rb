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
  include ReleaseManager::VCSManager

  def initialize(module_path, version, options = {})
    @options = options
    @root_dir = module_path
    @version = version
  end

  def empty_changelog_contents
    "# #{module_name}\n\n## Unreleased\n"
  end

  def module_name
    metadata['name']
  end

  def path
    @root_dir
  end

  # Create the changelog entries and commit
  # @param remote [Boolean] - if the commit is a remote git on the vcs server
  # @return [String] - sha of the commit
  def run(remote = false, branch = 'master')
    if already_released?
      logger.fatal "Version #{version} had already been released, did you bump the version manually?"
      exit 1
    end
    File.write(changelog_file, new_content) unless remote
    id = commit_changelog(nil, remote, branch) if options[:commit]
    logger.info "The changelog has been updated to version #{version}"
    id
  end

  # @returns [String] the full path to the change log file
  def changelog_file
    options[:file] || File.join(root_dir, 'CHANGELOG.md')
  end

  # @returns [Array[String]]
  def changelog_lines
    unless @changelog_lines
      @changelog_lines = File.exists?(changelog_file) ?
          File.readlines(changelog_file) : empty_changelog_contents.lines
    end
    @changelog_lines
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

  # @return [Array] - array of lines of the unreleased content, text between unreleased and next version
  def get_unreleased_content
    start_content = changelog_lines.slice((unreleased_index + 1), changelog_lines.count)
    end_index = start_content.find_index {|line| line.downcase.start_with?('## version')}
    end_index ? start_content.slice(0, end_index) : start_content
  end

  # @return [Array] - array of lines of the specified version content, text between specified version and next version
  # @param [String] - the version of content you want
  # @note - returns empty string if version is not found
  def get_version_content(version)
    start_index = changelog_lines.find_index {|line| line.downcase.include?("version #{version}") }
    return nil unless start_index
    start_content = changelog_lines.slice((start_index + 1), changelog_lines.count)
    end_index = start_content.find_index {|line| line.downcase.start_with?('## version')}
    end_index ? start_content.slice(0, end_index) : start_content
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
  def commit_changelog(msg = nil, remote = false, branch = 'master')
    message = msg || "[ReleaseManager] - bump changelog to version #{version}"
    if remote
      actions = [{
         action: 'update',
         file_path: changelog_file.split(repo.workdir).last,
         content: new_content
      }]
      obj = vcs_create_commit(source, branch, message, actions)
      obj.id if obj
    else
      add_file(changelog_file)
      create_commit(message)
    end
  end

  # checks to make sure the unreleased line is valid, and the file exists
  def self.check_requirements(path)
    log = new(path, nil)
    log.unreleased_index
  end

  private

  # @returns [Hash] the metadata object as a ruby hash
  def metadata
    unless @metadata
      metadata_file =File.join(path, 'metadata.json')
      raise ModNotFoundException unless File.exists?(metadata_file)
      @metadata ||= JSON.parse(File.read(metadata_file))
    end
    @metadata
  end

  def source
    metadata['source']
  end
end


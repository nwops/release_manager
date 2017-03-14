#!/usr/bin/env ruby
#
#
#Author: Corey Osman
#Purpose: updates the changelog.md file with the new version by reading the metadata.json file
#Usage: ./bump_log.rb [CHANGELOG.md]
#
require 'json'
require 'optparse'

@options = {}
OptionParser.new do |opts|
  opts.banner = "Usage #{__FILE__}"
  opts.on("-c", "--[no-]commit", "Commit the updated changelog") do |c|
    @options[:commit] = c
  end
  opts.on("-f", "--changelog FILE", "Path to the changelog file") do |c|
    @options[:file] = c
  end
end.parse!

def options
  @options
end

class String
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end
end

# @returns [String] the root directory of the project calculated from this file
def root_dir
  File.expand_path File.dirname File.dirname(__FILE__)
end

# @returns [Hash] the metadata object as a ruby hash
def metadata
  file = File.join(root_dir, 'metadata.json')
  JSON.parse(File.read(file))
end

# @returns [String] the version found in the metadata file
def version
   metadata['version'] 
end

# @returns [String] the full path to the change log file
def changelog_file
  file = ARGV.first || options[:file] || File.join(root_dir, 'CHANGELOG.md')
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

# @returns [Integer] line number of where the work unreleased is located
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

def create_commit
  `git add #{changelog_file}`
  puts `git commit -m "[Autobot] - bump changelog to version #{version}"`
end

# write the new changelog unless it does not need updating
if already_released? 
  puts "Fail: Version #{version} had already been released, did you bump the version?".red
  exit 1
else
  File.write(changelog_file, new_content) 
  create_commit if options[:commit] 
  puts "Success: The changelog has been updated to version #{version}".green
end


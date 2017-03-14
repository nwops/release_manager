#!/usr/bin/env ruby
#
# Author: Corey Osman
# Purpose: release a new version of a module or r10k-control from the src branch by performing
#          the following tasks:
#           - bump version in metadata file
#           - bump changelog version using version in metadata file
#           - tag the code matching the version in the metadata file
#           - push to upstream
#  This script can be used on modules or r10k-control.  If using on a module
#  be sure to pass in the repo path using --repo.  The repo is where this script
#  pushes too. 
#
#  You should also use the -d feature which simulates a run of the script without doing
#  anything harmful.
#
#  Run with -h to see the help
require 'json'
require 'optparse'

# @returns [String] the root directory of the project calculated from this file
def root_dir
  File.dirname(File.expand_path(File.dirname(__FILE__)))
end

# @returns [Hash] the metadata object as a ruby hash
def metadata
  file = File.join(root_dir, 'metadata.json')
  @metadata ||= JSON.parse(File.read(file))
end

def options
  @options ||= {}
end

def scripts_dir 
  @scripts_dir ||= File.expand_path(File.dirname(__FILE__))
end

def upstream_repo
  unless @upstream_repo
    @upstream_repo = options[:repo] || ENV['UPSTREAM_REPO'] || metadata["source"] 
    if @upstream_repo.nil?
      puts "Please supply a repo"
      exit 1
    end
  end
  @upstream_repo
end

OptionParser.new do |opts|
  opts.banner = "Usage #{__FILE__}"
  opts.on("-d", "--dry-run", "Do a dry run, without making changes") do |c|
    options[:dry_run] = c
  end
  opts.on('-a', '--auto', 'Run this script without interaction') do |c|
    options[:auto] = c
  end
  opts.on('-b', '--no-bump', "Do not bump the version in metadata.json") do |c|
    options[:bump] = c
  end
  opts.on('-r', '--repo REPO', "The repo to use, defaults to: #{upstream_repo}") do |c|
    options[:repo] = c
  end
  opts.on('--verbose', "Extra logging") do |c|
    options[:verbose] = c
  end
end.parse!


# @returns [String] the name of the module found in the metadata file
def mod_name
  metadata['name']
end

# @returns [String] - the source branch to push to
# if r10k-control this branch will be dev, otherwise master
def src_branch
  return 'dev' if mod_name == 'r10k-control'
  'master'
end

# @returns [String] the version found in the metadata file
def version
   return metadata['version'].next if dry_run?
   metadata['version']
end

def tag 
  return "Would have just tagged the module to #{version}" if dry_run?
  `bundle exec rake module:tag` 
end

def bump 
  return "Would have just bumped the version to #{version}" if dry_run?
  @metadata = nil
  `bundle exec rake module:bump_commit` unless options[:bump]
end

def bump_log 
  return "Would have just bumped the CHANGELOG to version #{version}" if dry_run?
  bump_log_script = File.join(scripts_dir, 'bump_log.rb')
  `#{bump_log_script} -c`
end

def push 
  return "Would have just pushed the code and tag to #{upstream_repo}" if dry_run?
  `git push #{upstream_repo} #{src_branch} --tags`
end

def dry_run?
  options[:dry_run] == true
end

def auto_release?
  options[:auto] || ENV['AUTO_RELEASE'] == 'true'
end

# runs all the required steps to release the software 
# currently this must be done manually by a release manager
# 
def release 
  # updates the metadata.js file to the nexter version
  puts bump
  # updates the changelog to the next version based on the metadata file
  puts bump_log
  # tags the r10k-module with the version found in the metadata.json file
  puts tag
  # pushes the updated code and tags to the upstream repo
  if auto_release? 
   puts push
   return
  end
  print "Ready to release version #{version} to #{upstream_repo}\n and forever change history(y/n)?: ".yellow
  answer = gets.downcase.chomp
  if answer == 'y'
    puts push 
    $?.success?
  else
    puts "Nah, forget it, this release wasn't that cool anyways.".yellow
    false 
  end 
end

def add_upstream_remote
  upstream = `git config --get remote.upstream.url`.chomp
  if upstream != upstream_repo 
    print "Ok to change your upstream repo from #{upstream}\n to #{upstream_repo}? (y/n)"
    answer = gets.downcase.chomp
    if answer == 'y'
      # something else we can't identify
      if upstream != ''
      `git remote rm upstream`
      end
      `git remote add upstream #{upstream_repo}`
    end
  end
  value = `git fetch upstream`
  puts value unless $?.success?
end

def branch_exists?(name)
  `git branch |grep '#{name}$'`
  $?.success?
end

def verbose?
  options[:verbose]
end
# ensures the dev branch has been created and is up to date
def create_dev_branch 
  puts "git checkout -b #{src_branch} upstream/#{src_branch}" if verbose?
  `git checkout -b #{src_branch} upstream/#{src_branch}` unless branch_exists?(src_branch)
  # ensure we have updated our local branche
  `git checkout #{src_branch}`
  `git rebase "upstream/#{src_branch}" `
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
  
def yellow 
    colorize(33)
  end
end

# ensure we have upstream setup properely (comes from common.sh)
#add_upstream_remote
create_dev_branch
value = release
unless value
  exit 1 
end

puts "Releasing Version #{version} to #{upstream_repo}".green
puts "Version #{version} has been released successfully".green 
puts "Although this was a dry run so nothing really happended".green if dry_run?
exit 0

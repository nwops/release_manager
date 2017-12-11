require "release_manager/version"
require "release_manager/module_deployer"
require "release_manager/release"
require "release_manager/changelog"
require 'release_manager/logger'
require 'release_manager/workflow_action'
require 'release_manager/sandbox'

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

  def fatal
    red
  end

  def yellow
    colorize(33)
  end
end
module ReleaseManager
  def self.gitlab_server
    if ENV['GITLAB_API_ENDPOINT']
      if data = ENV['GITLAB_API_ENDPOINT'].match(/(https?\:\/\/[\w\.]+)/)
        return data[1]
      end
    end
    'https://gitlab.com'
  end
end


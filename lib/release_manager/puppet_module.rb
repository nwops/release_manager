require 'json'
require_relative 'errors'
class PuppetModule
 attr_reader :name, :metadata_file, :mod_path
 
 def initialize(mod_path)
   @mod_path = mod_path
   @metadata_file = File.join(mod_path, 'metadata.json')  
 end

 def name
   namespaced_name.split(/\/|\-/).last
 end
 
 def namespaced_name 
   metadata['name']
 end
 # @returns [Hash] the metadata object as a ruby hash
 def metadata
   unless @metadata
     raise ModNotFoundException unless File.exists?(metadata_file) 
     @metadata ||= JSON.parse(File.read(metadata_file))
   end
   @metadata
 end

 def tags
  `git --git-dir=#{mod_path}/.git tag`.split("\n")
 end

 def latest_tag
   tags.last 
 end

 # @returns [String] the name of the module found in the metadata file
 def mod_name
   metadata['name']
 end

 # @returns [String] the version found in the metadata file
 def version
   metadata['version']
 end

end

require 'yaml'
require 'json'
require 'rubygems'
require 'bundler/setup'
require File.join(File.dirname(__FILE__), '../lib/ScenarioLogger')
require File.join(File.dirname(__FILE__), '../lib/HttpRequests')
require File.join(File.dirname(__FILE__), '../lib/BgRequests')
require File.join(File.dirname(__FILE__), 'util')

# Start the logger
$scenario_logger = ScenarioLogger.new("logs/test.log")

# Set the profile values we have selected
profile_running = Util.new.get_profile
profile_config_dict = YAML.load_file("config/profile_data/#{profile_running}.yml")
profile_config_dict.each do |key, value|
	  ENV.store(key,value.to_s)
end

# Set the available endpoints
$endpoints = Hash.new
endpoints_config_dict = Util.new.load_profile()
endpoints_config_dict['endpoints'].each do |key, value|
    instance = Kernel.const_get(value['class_name']).new(value)
    $endpoints[key] = instance
end

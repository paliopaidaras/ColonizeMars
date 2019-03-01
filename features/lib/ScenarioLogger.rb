require 'logger'
require 'time'

class ScenarioLogger
	def initialize(filename)
		logger_path = File.dirname(filename)

		if !Dir.exists?(logger_path)
			Dir.mkdir(logger_path)
		end

		@logger = Logger.new(filename)
		@scenario_logs = ""
	end

	def log(message)
		max_log = ENV['MAX_LOG_SIZE'].to_i
		message = message[0..max_log] if message.length > max_log

		@logger.info(message)
		timestamp = Time.now.getutc
		@scenario_logs += "[#{timestamp}] #{message}\n"
	end

	def new_scenario()
		@scenario_logs = ""
	end

	def get_current_logs()
		return @scenario_logs
	end

end

Before do |scenario|
	$scenario_logger.new_scenario()
	$scenario_logger.log("Starting Scenario : #{scenario.name}")
end

After do |scenario|
	$scenario_logger.log("Ending Scenario : #{scenario.name}")
end

class Util
	def get_profile
		found = false
		ARGV.each do |arg|
			if found
				return arg
			end
			if arg == '-p' || arg == '--profile'
				found = true
			end
		end
		return 'bg_mars'
	end

	def load_profile
		begin
			profile = get_profile()
			if ( ! File.file?("config/profiles/#{profile}.yml") )
				raise "Environment file: config/profiles/#{profile}.yml does NOT exist"
			else
				ret_hash = Hash.new
				profile_hash = YAML.load_file("config/profiles/#{profile}.yml")

				if profile_hash.key?('endpoints')
					ret_hash['endpoints'] = profile_hash['endpoints']
				else
					raise "No endpoints available to load from config file config/profiles/#{profile}.yml"
				end
				return ret_hash
			end
		rescue Exception => e
			raise "[Error]: Issue loading profile config for profile '#{profile}' #{e}\n"
		end
	end
end

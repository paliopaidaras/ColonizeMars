require 'erb'
require 'nokogiri'
require 'uri'

class BgRequests < HttpRequests
	def initialize(args)
		if args.length > 0
			host = args['host']
			uri = args['uri']
			protocol = args['protocol']

			@url = "#{protocol}://#{host}#{uri}"
			super()
		else
			raise "No args for initializing BgRequests object"
		end
	end

	def submit_get_request(param_map, uri_extention:'', headers:{})
		get_body = _process_param_map(param_map)
		get_body = '?'+get_body if get_body != ''
		return make_get_request(@url+uri_extention+get_body, headers:headers)
	end

	def submit_post_request(param_map, headers:{})
		post_body = _process_param_map(param_map)
		return make_post_request(@url, post_body, headers:headers)
	end

	private
		def _process_param_map(param_map)
			body = ''
			param_map.each do |key, value|
				body << '&' if body != ''
				body << key << '=' << value
			end
			return body
		end
end

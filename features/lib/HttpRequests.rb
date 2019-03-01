require 'erb'
require 'nokogiri'
require 'uri'
require 'curb'

class HttpRequests
	def initialize()
		@last_request = {}
		@last_response = {}
		@last_response_status = {}
	end

	def make_get_request(url, headers:{})
		return _make_request(url, "GET", {}, headers:headers)
	end

	def make_post_request(url, post_body, headers:{})
		return _make_request(url, "POST", {'post_body' => post_body}, headers:headers)
	end

	private
		def _log_and_set_last_request(type, url, body:{}, headers:{})
			@last_request['type'] = type
			@last_request['url'] = url
			@last_request['body'] = body if body != {}
			@last_request['headers'] = headers if headers != {}

			# Log the request format
			log = "Submitting #{type} request to url: #{url}"
			log +=" with body: #{body}" if body != {}
			log += " and headers: #{headers}" if headers != {}
			$scenario_logger.log "Class HttpRequests/_make_request() --> #{log}"
		end

		def _make_request(url, type, options, headers:{})
			# Initialize Curl instance
			curl_instance = Curl::Easy.new(url)
			curl_instance.ssl_verify_peer = false
			curl_instance.ssl_verify_host = false
			curl_instance.post_body = options['post_body'] if type.eql? 'POST' # Add the post request body if available
			curl_instance.headers = headers # Add headers if available
			curl_instance.connect_timeout = ENV['CONNECTION_TIMEOUT'].to_i # set timeout

			# Submit the request
			raise "HttpRequests class does not yet support submit method of type: '#{type}'" unless ['GET','POST'].include? type
			_log_and_set_last_request(type, url, body:options, headers:headers)
			curl_instance.http_post if type.eql? 'POST'
			curl_instance.perform if type.eql? 'GET'

			# Parse the response
			@last_response = curl_instance.body_str
			@last_response_status, *last_request_headers = curl_instance.header_str.split(/[\r\n]+/).map(&:strip)

			$scenario_logger.log "Response Status : #{@last_response_status} --> Response Body: #{curl_instance.body_str}"
			return @last_request, @last_response, @last_response_status
		end
end

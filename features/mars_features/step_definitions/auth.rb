Given(/^I login with valid credentials$/) do
	step "I submit a login with VALID mail and VALID password"
end

Given(/^I submit a login with (VALID|INVALID|EMPTY|WRONG) mail and (VALID|EMPTY|WRONG) password$/) do |email_type, passwd_type|
	# Fill variables that will be sent in the request
	inputMap = {}
	inputMap['email'] = '' if email_type.eql? 'EMPTY'
	inputMap['email'] = ENV["#{email_type}_EMAIL"] if email_type != 'EMPTY'
	inputMap['password'] = '' if email_type.eql? 'EMPTY'
	inputMap['password'] = ENV["#{passwd_type}_PASSWORD"] if passwd_type != 'EMPTY'

	# Submit login request for email
	@last_request, @last_response, @last_response_status = $endpoints['login'].submit_post_request(inputMap)
	@last_response = JSON.parse(@last_response)
	@login_info = @last_response
	$scenario_logger.log "Login submitted and info returned: #{@last_response}"
end

When(/^I refresh my token with (VALID|INVALID|EMPTY|WRONG) mail and (VALID|INVALID|EMPTY) previous token$/) do |email_type, token_type|
	# Verify we have a login available
	raise "No valid Login info available" if @login_info.nil? or @login_info['code'] != nil

	# Fill variables that will be sent in the request
	inputMap = {}
	inputMap['email'] = '' if email_type.eql? 'EMPTY'
	inputMap['email'] = ENV["#{email_type}_EMAIL"] if email_type != 'EMPTY'
	inputMap['refreshToken'] = '' if token_type.eql? 'EMPTY'
	inputMap['refreshToken'] = @login_info['token']['refreshToken'] if token_type.eql? 'VALID'
	inputMap['refreshToken'] = ENV["INVALID_TOKEN"] if token_type.eql? 'INVALID'

	# Submit login request for email
	@last_request, @last_response, @last_response_status = $endpoints['refresh-token'].submit_post_request(inputMap)
	@last_response = JSON.parse(@last_response)
	@login_info['token'] = @last_response
	$scenario_logger.log "Refresh-token submitted and info returned: #{@last_response}"
end

Then(/^the logged in user has the correct email$/) do
	# Verify we have a login available
	raise "No valid Login info available" if @login_info.nil? or @login_info['code'] != nil

	# Validate the email in the login
	unless @login_info['user']['email'].include? ENV["VALID_EMAIL"]
		exit_fail "The user that logged in does not have the expected email: '#{ENV["VALID_EMAIL"]}' but has: '#{@login_info['user']['email']}'"
	end

	# Validate the elements of the response
	['tokenType','accessToken','refreshToken','expiresIn'].each do |token_element|
		exit_fail "Logged user lacks token element: '#{token_element}'" if @last_response['token'][token_element].nil?
	end
	['id','name','email','picture','role','createdAt'].each do |user_element|
		exit_fail "Logged user lacks user element: '#{user_element}'" if @last_response['user'][user_element].nil?
	end
	$scenario_logger.log "Logged user has all mandatory attributes and the expected email: '#{@login_info['user']['email']}'"
end

Then(/^response status has (SUCCESS|BAD_REQUEST|UNAUTHORIZED_USER|NOT_FOUND|CONFLICT) code(?:| due to (.*))$/) do |code_type,fail_reason|
	# Verify status
	expected_status_code = ENV["#{code_type}_CODE"]
	exit_fail "No response status available" if @last_response_status.nil? or @last_response_status.nil?
	unless @last_response_status.include? expected_status_code
		exit_fail "Expected status code of last request is: '#{expected_status_code}', but actual code is: '#{@last_response_status}'"
	end

	if code_type.eql? 'SUCCESS'
		# Verify response does not contain a code in case of success
		exit_fail "Successful response should not contain an error code. Code found: #{@last_response['code']}" if @last_response['code'] != nil
		exit_fail "Successful response should not contain a failure message" if @last_response['message'] != nil
	else
		# Verify failure reason if set
		if fail_reason != nil and ! @last_response['message'].include? fail_reason
			exit_fail "Failure reason was expected to be: '#{fail_reason}' but actual found: '#{@last_response['message']}'"
		end
	end
	$scenario_logger.log "Status of the last request is '#{code_type}' as expected with message: '#{fail_reason}'"
end

def exit_fail(error_message)
	raise "#{error_message}\n - Last request:#{@last_request}\n - Last response: #{@last_response}"
end

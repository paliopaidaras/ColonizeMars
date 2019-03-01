Given(/^I choose one of the available years of the unit for booking$/) do
	# Verify we have viewed a unit and it has available years to book
	exit_fail "No unit selected from previous request" if @last_unit_response.nil? or @last_unit_response['id'].nil?
	exit_fail "Unit with id: '#{@last_unit_response['id']}' has no years avalable for booking" if @last_unit_response['availability'].empty?

	@selected_year_to_book = @last_unit_response['availability'][0]
	$scenario_logger.log "Selected year for booking: #{@selected_year_to_book}"
end

Then(/^unit should(?:| (not)) be available for booking at (?:a|the) (SELECTED|UNAVAILABLE) year$/) do |not_flag, year_type|
	# Verify we have viewed a unit
	exit_fail "No unit selected from previous request" if @last_unit_response.nil? or @last_unit_response['id'].nil?
	exit_fail "No selected year to book" if year_type.eql? 'SELECTED' and @selected_year_to_book.nil?

	# Set the year accordingly
	year = @selected_year_to_book if year_type.eql? 'SELECTED'
	year = ENV['UNAVAILABLE_YEAR'] if year_type.eql? 'UNAVAILABLE'

	# Verification
	if not_flag.nil? and year_type.eql? 'UNAVAILABLE'
		raise "You cannot call positive availability for an UNAVAILABLE year"
	elsif not_flag.nil? and year_type.eql? 'SELECTED'
		# Verify year of the unit is available
		unless @last_unit_response['availability'].include? year
			exit_fail "We expected year #{year} to be available, but was not found in the available years: #{@last_unit_response['availability']}"
		end
	else
		# Verify year of the unit is not available
		if @last_unit_response['availability'].include? year
			exit_fail "We expected year #{year} to be booked, but was found in the available years: #{@last_unit_response['availability']}"
		end
	end
	$scenario_logger.log "Unit with id '#{@last_unit_response['id']}' is#{not_flag} available as expected for year #{year}"
end

When(/^I try to book the (SELECTED|WRONG) unit for (?:an|the) (SELECTED|UNAVAILABLE) year(?:| with an? (INVALID|EXPIRED) token)$/) do
	|unit_type, year_type, token_type|
	# Verify we have a response available and a unit_id also
	exit_fail "No valid response available to parse" if @last_response.nil? or @last_response['code'] != nil
	exit_fail "No unit selected from previous request" if @last_unit_response.nil? or @last_unit_response['id'].nil?
	exit_fail "No selected year to book" if @selected_year_to_book.nil?

	# Setup the header that we need for this request
	headers = {} # Example header: 'Authorization Bearer [AccessToken]'
	token = ENV["#{token_type}_TOKEN"] if token_type != nil
	token = @login_info['token']['accessToken'] if token_type.nil?
	headers['Authorization'] = "#{@login_info['token']['tokenType']} #{token}"

	# Setup the parameters for the request
	inputMap = {}
	inputMap['unitId'] = @last_unit_response['id'].to_s if unit_type.eql? 'SELECTED'
	inputMap['unitId'] = ENV["WRONG_UNIT_ID"].to_s if unit_type.eql? 'WRONG'
	inputMap['year'] = ENV["UNAVAILABLE_YEAR"].to_s if year_type.eql? 'UNAVAILABLE'
	inputMap['year'] = @selected_year_to_book.to_s if year_type.eql? 'SELECTED'

	# Submit login request for email
	@last_request, @last_response, @last_response_status = $endpoints['book'].submit_post_request(inputMap, headers:headers)
	@last_response = JSON.parse(@last_response)
	$scenario_logger.log "Booking a #{unit_type} unit with id: '#{inputMap['unitId']}' submitted and info returned: #{@last_response}"
end

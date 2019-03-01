When(/^I request to list(?:| (all)) the units(?:| with an (INVALID|EXPIRED) token)(?:| of page number (\d+) for (\d+) units per page)(?:| filtering with querry (.*))$/) do
	|all_units, token_type, page, perPage, querry|
	# Verify we have a login available
	raise "No valid Login info available" if @login_info.nil? or @login_info['code'] != nil

	# Adapt arguments in case of all units request
	if all_units != nil
		token_type = nil
		page = '1'
		perPage = ENV['MAX_UNITS_PER_PAGE'].to_s
	end

	# Setup the header that we need for this request
	headers = {} # Example header: 'Authorization Bearer [AccessToken]'
	token = ENV["#{token_type}_TOKEN"] if token_type != nil
	token = @login_info['token']['accessToken'] if token_type.nil?
	headers['Authorization'] = "#{@login_info['token']['tokenType']} #{token}"

	# Allow SQL injection and maybe create a testcase that will try this and will break the system

	# Setup the parameters for the request
	inputMap = {}
	inputMap['q'] = querry.to_s if querry != nil
	inputMap['page'] = page.to_s if page != nil
	inputMap['perPage'] = perPage.to_s if perPage != nil

	# Submit login request for email
	@last_request, @last_response, @last_response_status = $endpoints['units'].submit_get_request(inputMap, headers:headers)
	@last_response = JSON.parse(@last_response)
	$scenario_logger.log "List units submitted and info returned: #{@last_response}" if perPage.to_i <= 10

	if @last_response['data'] != nil
		@units = {}
		@units['ids'] = @last_response['data'].map {|unit| unit['id']}
		@units['count_ids'] = @units['ids'].length
	end
end

Then (/^the(?:| filtered) units returned are equal to totalCount in meta data$/) do
	exit_fail "Last request was not a successful listing request" if @units.nil? or @units['ids'].nil?
	unless @last_response['meta']['totalCount'].to_i.eql? @units['count_ids']
		exit_fail "Units returned from the listing request '#{@units['count_ids']}' do not match totalCount in the meta data '#{@last_response['meta']['totalCount']}'"
	end
	$scenario_logger.log "The units returned match the meta data totalCount"
end

When(/^I select to view a (VALID|WRONG) unit(?:| with an? (INVALID|EXPIRED) token)$/) do
	|unit_type, token_type|
	# Verify we have a login available
	raise "No valid Login info available" if @login_info.nil? or @login_info['code'] != nil

	# Setup the header that we need for this request
	headers = {} # Example header: 'Authorization Bearer [AccessToken]'
	token = ENV["#{token_type}_TOKEN"] if token_type != nil
	token = @login_info['token']['accessToken'] if token_type.nil?
	headers['Authorization'] = "#{@login_info['token']['tokenType']} #{token}"

	# Setup the parameters for the request
	raise "Please list units in order to select one" if @units.nil? or @units['ids'].nil?
	if unit_type.eql? 'WRONG'
		uri_extention = '/'+ENV['WRONG_UNIT_ID'].to_s
		if @units['ids'].include? ENV['WRONG_UNIT_ID'].to_s
			raise "Wrong unit_id: '#{ENV['WRONG_UNIT_ID']}' should not have been included in unit_ids: #{@units['ids']}"
		end
	elsif unit_type.eql? 'VALID'
		uri_extention = '/'+get_a_random_valid_unit_id.to_s
	end

	# Submit login request for email
	@last_request, @last_response, @last_response_status = $endpoints['units'].submit_get_request({}, uri_extention:uri_extention, headers:headers)
	@last_response = JSON.parse(@last_response)
	$scenario_logger.log "Viewing of a #{unit_type} unit submitted and info returned: #{@last_response}"

	# Storing the unit_id that we are currently viewing
	@last_unit_response = @last_response
end

When(/^I select to view the unit again$/) do
	# Verify we have a login available
	raise "No valid Login info available" if @login_info.nil? or @login_info['code'] != nil
	exit_fail "No unit selected from previous request" if @last_unit_response.nil? or @last_unit_response['id'].nil?

	# Setup the header that we need for this request
	headers = {} # Example header: 'Authorization Bearer [AccessToken]'
	headers['Authorization'] = "#{@login_info['token']['tokenType']} #{@login_info['token']['accessToken']}"

	# Setup the parameters for the request
	uri_extention = '/'+@last_unit_response['id']

	# Submit login request for email
	@last_request, @last_response, @last_response_status = $endpoints['units'].submit_get_request({}, uri_extention:uri_extention, headers:headers)
	@last_response = JSON.parse(@last_response)
	$scenario_logger.log "Submit to view again the unit_id: '#{@last_unit_response['id']}'. Info returned: #{@last_response}"

	# Storing the unit_id that we are currently viewing
	@last_unit_response = @last_response
end

Then(/^the returned page contains (\d+) units in page from (\d+) units returned(?:| and all units are filtered by (.*))$/) do
	|page_units, total_units, querry|
	# Verify we have a response available
	exit_fail "No valid response available to parse" if @last_response.nil? or @last_response['code'] != nil

	# Verify the corrent number of total units
	unless @last_response['meta']['totalCount'].to_i == total_units.to_i
		exit_fail "Expected #{total_units} total units in the response, but found actual #{@last_response['meta']['totalCount']}"
	end

	# Verify that all units in the page have all the elements as expected
	@last_response['data'].each do |unit|
		exit_fail "ID is not present for all units in the page" if unit['id'].nil?
		unit_id = unit['id']
		['name','region','description','price','cancellation','rating','pictures'].each do |element|
			exit_fail "Unit with id: '#{unit_id}' does not have element: '#{element}'" if unit[element].nil?
		end
	end

	# Verify the page returned has the corrent number of units
	current_page_units = 0
	@last_response['data'].each do |unit|
		exit_fail "ID is not present for all units in the page" if unit['id'].nil?
		current_page_units += 1
	end

	unless current_page_units.to_i == page_units.to_i
		exit_fail "Expected #{page_units} present in the page, but found actual #{current_page_units} in the page"
	end
	$scenario_logger.log "Last response has #{current_page_units} unit-ids as expected"

	# Verify the units returned have the correct filtering, according to querry
	unless querry.nil?
		correct_filter_units = 0
		@last_response['data'].each do |unit|
			correct_filter_units += 1 if unit.flatten.include? querry
		end

		unless current_page_units.to_i == correct_filter_units.to_i
			exit_fail "Expected filter: '#{querry}' should have applied to #{current_page_units} units in page, but applied only to #{correct_filter_units}"
		end
		$scenario_logger.log "All #{current_page_units} units from last response contain text: '#{querry}'"
	end
end

Then(/^the returned unit(?:|(s)) contains? all the elements correctly$/) do | multiple_units |
	# Verify we have a response available
	exit_fail "No valid response available to parse" if @last_response.nil? or @last_response['code'] != nil

	if multiple_units.nil?
		exit_fail "Last response does not contain a single unit as expected" if @last_response['id'].nil?
		validate_unit_has_all_elements(@last_response)
	else
		exit_fail "Last response does not contain a multiple units as expected" if @last_response['data'].nil? or @last_response['data'].length < 1
		@last_response['data'].map {|unit_details| validate_unit_has_all_elements(unit_details, multiple_units:'yes')}
	end
	$scenario_logger.log "Unit/s from last response are validated to have all mandatory elements"
end

## Performance step that sends 100 requests
#Given (/^I send 100 List Units request$/) do
#	$scenario_logger.log "Submitting 40 List Units requests for all units in one page"
#	for i in 1..40 # Send 40 requests that return all units
#		step "I request to list all the units"
#	end
#	$scenario_logger.log "Submitting 40 List Units requests for all units and go to page 10 with 5 units per page"
#	for i in 1..40 # Send 40 requests that return all units with paging
#		step "I request to list the units of page number 10 for 5 units per page"
#	end
#	$scenario_logger.log "Submitting 20 List Units requests for units filtered with Arabia and go to page 2 with 3 units per page"
#	for i in 1..20 # Send 20 requests that return some units filtered by a querry
#		step "I request to list the units of page number 2 for 3 units per page filtering with querry Arabia"
#	end
#end

def get_a_random_valid_unit_id()
	raise "No listed units, in order to select a valid unit to view" if @units.nil? or @units['ids'].nil? or @units['ids'].length < 1
	return @units['ids'].sample
end

def validate_unit_has_all_elements(unit_details, multiple_units:nil)
	mandatory_elements = ['name','region','description','price','cancellation','rating','pictures']
	mandatory_elements << 'availability' << 'amenities' if multiple_units.nil?

	# Validate the elements of the response
	exit_fail "Unit details given do not contain an id field: #{unit_details}" if unit_details['id'].nil?
	mandatory_elements.each do |unit_element|
		exit_fail "Unit with id: '#{unit_details['id']}' lacks element: '#{unit_element}' --> details: #{unit_details}" if unit_details[unit_element].nil?
	end
end

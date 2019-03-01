@regression
@Units
Feature: BlueGround Colonizing Mars 2080 - Units

Background:
	Given I login with valid credentials
	@success_list_units
	Scenario: Verify successful listing of units
	Given I request to list the units
	When response status has SUCCESS code
	Then the returned page contains 10 units in page from 60 units returned

	@success_paging_list_units
	Scenario: Verify successful listing of units with paging
	When I request to list the units of page number 5 for 2 units per page
	Then the returned page contains 2 units in page from 60 units returned

	@filtered_list_units
	Scenario Outline: Verify successful listing of units whith filtering
	When I request to list the units of page number 5 for 1 units per page filtering with querry Arabia
	Then the returned page contains 1 units in page from 9 units returned and all units are filtered by Arabia

	Examples:
	| page | units_per_page | page_units | total_units | querry |
	| 5    | 1              | 1          | 9           | Arabia |
	| 2    | 10             | 0          | 9           | Arabia |

	@empty_list_units
	Scenario: Verify empty listing of units with wrong filtering
	When I request to list the units filtering with querry ErrorQuerry
	Then the returned page contains 0 units in page from 0 units returned

	@fail_token_list_units
	Scenario Outline: Verify failure when listing units with invalid/expired token
	When I request to list the units with an <token_type> token
	Then response status has UNAUTHORIZED_USER code due to <failure_reason>

	Examples:
	| token_type | failure_reason |
	| INVALID    | jwt malformed  |
	| EXPIRED    | jwt expired    |

	@success_list_filtered_units
	Scenario: Verify valid unit is returned correctly
	When I request to list all the units filtering with querry Arabia
	Then the filtered units returned are equal to totalCount in meta data

	@success_list_all_units
	Scenario: Verify meta data totalCount is reflected on the actual units returned 
	When I request to list all the units
	Then the units returned are equal to totalCount in meta data

	@success_view_unit
	Scenario: Verify valid unit is returned correctly
	Given I request to list all the units
	When I select to view a VALID unit
	Then the returned unit contains all the elements correctly

	@fail_view_unit
	Scenario: Verify failure when trying to view a non existent unit
	Given I request to list all the units
	When I select to view a WRONG unit
	Then response status has NOT_FOUND code due to Unit does not exist

	@fail_token_view_unit
	Scenario Outline: Verify failure when trying to view a valid unit with an expired/invalid token
	Given I request to list all the units
	When I select to view a VALID unit with an <token_type> token
	Then response status has UNAUTHORIZED_USER code due to <failure_reason>

	Examples:
	| token_type | failure_reason |
	| EXPIRED    | jwt expired    |
	| INVALID    | jwt malformed  |

	#@performance_list_units
	#Scenario: (Optional) Performance testing the List Units request to not fall bellow 300ms
	#When I send 100 List Units request

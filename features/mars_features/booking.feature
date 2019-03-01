@regression
@Book
Feature: BlueGround Colonizing Mars 2080 - Units

Background:
	Given I login with valid credentials
	And I request to list all the units
	And the returned units contains all the elements correctly
	And I select to view a VALID unit

	@success_book_unit_request
	Scenario: Verify request for booking a unit can be submitted successfully
	Given I choose one of the available years of the unit for booking
	When I try to book the SELECTED unit for the SELECTED year
	Then response status has SUCCESS code

	@success_book_unit
	Scenario: Verify unit can be booked succesfully
	Given I choose one of the available years of the unit for booking
	When I try to book the SELECTED unit for the SELECTED year
	And response status has SUCCESS code
	And I select to view the unit again
	Then unit should not be available for booking at the SELECTED year

	@fail_double_book_unit
	Scenario: Verify re-booking a unit will fail for a specific year
	Given I choose one of the available years of the unit for booking
	And I try to book the SELECTED unit for the SELECTED year
	And response status has SUCCESS code
	When I try to book the SELECTED unit for the SELECTED year
	Then response status has CONFLICT code due to Unit changed
	And unit should not be available for booking at the SELECTED year

	@fail_book_unit
	Scenario: Verify booking a unit will fail for erroneous input
	Given I choose one of the available years of the unit for booking
	When I try to book the WRONG unit for the SELECTED year
	Then response status has NOT_FOUND code due to Unit does not exist

	@fail_token_book_unit
	Scenario Outline: Verify booking a unit will fail for erroneous input
	Given I choose one of the available years of the unit for booking
	When I try to book the SELECTED unit for the SELECTED year with a <token_type> token
	Then response status has <status> code due to <failure_reason>

	Examples:
	| token_type | status            | failure_reason |
	| INVALID    | UNAUTHORIZED_USER | jwt malformed  |
	| EXPIRED    | UNAUTHORIZED_USER | jwt expired    |

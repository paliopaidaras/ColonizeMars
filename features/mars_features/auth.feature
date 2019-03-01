@regression
@Authentication
Feature: BlueGround Colonizing Mars 2080 - Auth

	@success_login
	Scenario: Verify successful login with valid credentials
	Given I submit a login with VALID mail and VALID password
	When response status has SUCCESS code
	Then the logged in user has the correct email

	@fail_login
	Scenario Outline: Verify failing login with invalid input
	When I submit a login with <mail> mail and <password> password
	Then response status has <status> code due to <failure_reason>

	Examples:
	| mail    | password | status            | failure_reason              |
	| INVALID | VALID    | BAD_REQUEST       | Validation Error            |
	| EMPTY   | VALID    | BAD_REQUEST       | Validation Error            |
	| WRONG   | VALID    | BAD_REQUEST       | Validation Error            |
	| VALID   | EMPTY    | BAD_REQUEST       | Validation Error            |
	| VALID   | WRONG    | UNAUTHORIZED_USER | Incorrect email or password |

	@success_refresh_token
	Scenario: Verify successful refresh-token with valid credentials
	Given I submit a login with VALID mail and VALID password
	When I refresh my token with VALID mail and VALID previous token
	Then response status has SUCCESS code

	@fail_refresh_token
	Scenario Outline: Verify failing refresh-token with invalid input
	Given I submit a login with VALID mail and VALID password
	When I refresh my token with <mail> mail and <token> previous token
	Then response status has <status> code due to <failure_reason>

	Examples:
	| mail    | token   | status            | failure_reason                  |
	| INVALID | VALID   | BAD_REQUEST       | Validation Error                |
	| EMPTY   | VALID   | BAD_REQUEST       | Validation Error                |
	| WRONG   | VALID   | BAD_REQUEST       | Validation Error                |
	| VALID   | EMPTY   | BAD_REQUEST       | Validation Error                |
	| VALID   | INVALID | UNAUTHORIZED_USER | Incorrect email or refreshToken |

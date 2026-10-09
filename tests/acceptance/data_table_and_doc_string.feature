Feature: Data Table and Doc String
  A step can have both a Data Table and a Doc String.
  The step definition gets them in the order they are written.

  Background:
    Given a package

  Scenario: A Data Table before a Doc String
    Given a file named "features/arguments.feature" with
      """
      Feature: Step arguments
        Scenario: Both arguments
          Given a request
            | header | value |
            | Accept | json  |
            ```json
            {"id": 1}
            ```
          Then the request is ready
      """
    And a file named "features/setup-steps.R" with
      """
      given("a request", function(headers, body, context) {
        context$headers <- headers
        context$body <- body
      })
      then("the request is ready", function(context) {
        expect_equal(list(context$headers$value, context$body), list("json", "{\"id\": 1}"))
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes

  Scenario: A Doc String before a Data Table
    Given a file named "features/arguments.feature" with
      """
      Feature: Step arguments
        Scenario: Both arguments
          Given a request
            ```json
            {"id": 1}
            ```
            | header | value |
            | Accept | json  |
          Then the request is ready
      """
    And a file named "features/setup-steps.R" with
      """
      given("a request", function(body, headers, context) {
        context$headers <- headers
        context$body <- body
      })
      then("the request is ready", function(context) {
        expect_equal(list(context$headers$value, context$body), list("json", "{\"id\": 1}"))
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes

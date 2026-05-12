Feature: Scenario outlines

  Scenario: A scenario outline runs once per examples row
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/addition.feature" with
      """
      Feature: Addition
        Scenario Outline: Adding numbers
          Given I have <a>
          When I add <b>
          Then I get <result>

          Examples:
            | a | b | result |
            | 1 | 2 | 3      |
            | 4 | 5 | 9      |
            | 0 | 0 | 0      |
      """
    And a file named "features/setup-steps.R" with
      """
      given("I have {int}", function(n, context) {
        context$value <- n
      })
      when("I add {int}", function(n, context) {
        context$value <- context$value + n
      })
      then("I get {int}", function(n, context) {
        expect_equal(context$value, n)
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes
    And it has 3 passed

  Scenario: A failing outline row is reported without stopping other rows
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/addition.feature" with
      """
      Feature: Addition
        Scenario Outline: Adding numbers
          Given I have <a>
          When I add <b>
          Then I get <result>

          Examples:
            | a | b | result |
            | 1 | 2 | 3      |
            | 1 | 2 | 99     |
            | 4 | 5 | 9      |
      """
    And a file named "features/setup-steps.R" with
      """
      given("I have {int}", function(n, context) {
        context$value <- n
      })
      when("I add {int}", function(n, context) {
        context$value <- context$value + n
      })
      then("I get {int}", function(n, context) {
        expect_equal(context$value, n)
      })
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    And it has 2 passed

Feature: Running scenarios by name or line
  Run only some scenarios: the ones whose name matches a regular expression,
  or the ones at given lines of a feature file, like `features/addition.feature:3`.

  Background:
    Given a package
    And a file named "features/addition.feature" with
      """
      Feature: Addition
        Scenario: Adding small numbers
          Given I have 1
          Then I get 1

        Scenario: Adding big numbers
          Given I have 1000
          Then I get 1000

        Scenario Outline: Adding <n>
          Given I have <n>
          Then I get <n>

          Examples:
            | n |
            | 2 |
            | 3 |
      """
    And a file named "features/subtraction.feature" with
      """
      Feature: Subtraction
        Scenario: Subtracting small numbers
          Given I have 1
          Then I get 1
      """
    And a file named "features/setup-steps.R" with
      """
      given("I have {int}", function(n, context) {
        context$value <- n
      })
      then("I get {int}", function(n, context) {
        expect_equal(context$value, n)
      })
      """

  Scenario: Running scenarios whose name matches a regular expression
    When I run
      """
      test("features", name = "small")
      """
    Then it has 2 passed
    And it ran "Scenario: Adding small numbers"
    And it ran "Scenario: Subtracting small numbers"

  Scenario: A scenario runs if its name matches any of the regular expressions
    When I run
      """
      test("features", name = c("^Adding big", "^Subtracting"))
      """
    Then it has 2 passed
    And it ran "Scenario: Adding big numbers"
    And it ran "Scenario: Subtracting small numbers"

  Scenario: The name of an outline's example has its placeholders replaced
    When I run
      """
      test("features", name = "Adding 3")
      """
    Then it has 1 passed
    And it ran "Scenario: Adding 3"

  Scenario: Running the scenario at a line
    When I run
      """
      test("features", features = "addition.feature:6")
      """
    Then it has 1 passed
    And it ran "Scenario: Adding big numbers"

  Scenario: Running the scenarios at several lines
    When I run
      """
      test("features", features = c("addition.feature:2:6", "subtraction.feature:2"))
      """
    Then it has 3 passed

  Scenario: The line of a Scenario Outline runs all its examples
    When I run
      """
      test("features", features = "addition.feature:10")
      """
    Then it has 2 passed
    And it ran "Scenario: Adding 2"
    And it ran "Scenario: Adding 3"

  Scenario: The line of an example row runs only that example
    When I run
      """
      test("features", features = "addition.feature:17")
      """
    Then it has 1 passed
    And it ran "Scenario: Adding 3"

  Scenario: Running whole feature files
    When I run
      """
      test("features", features = "subtraction.feature")
      """
    Then it has 1 passed
    And only "Subtraction" was run

  Scenario: A feature file that doesn't exist is an error
    When I run
      """
      test("features", features = "multiplication.feature:2", stop_on_failure = FALSE)
      """
    Then the error message includes "Feature files not found."
    And the error message includes "multiplication.feature"

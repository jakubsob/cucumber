Feature: Scenario Outlines
  A Scenario Outline runs once for each row of its Examples.
  The `<placeholders>` are replaced with the row's values in the scenario name, steps, Doc Strings and Data Tables.

  Background:
    Given a package

  Scenario: A scenario outline runs once per examples row
    Given a file named "features/addition.feature" with
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
    Given a file named "features/addition.feature" with
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
    Then it has 1 failed
    And it has 2 passed
    And the output includes
      """
      3 scenarios (1 failed, 2 passed)
      """

  Scenario: Outline placeholders are replaced in the name, Doc Strings and Data Tables
    Given a file named "features/outline.feature" with
      """
      Feature: Outlines
        Scenario Outline: Greeting <name>
          Given a greeting
            ```
            Hello, <name>!
            ```
          And a person
            | name   |
            | <name> |
          Then the greeting is for the person

          Examples: People
            These are the people we greet.
            | name  |
            | Alice |
            | Bob   |
      """
    And a file named "features/setup-steps.R" with
      """
      given("a greeting", function(greeting, context) {
        context$greeting <- greeting
      })
      given("a person", function(person, context) {
        context$name <- person$name
      })
      then("the greeting is for the person", function(context) {
        expect_equal(context$greeting, paste0("Hello, ", context$name, "!"))
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes
    And it has 2 passed
    And it ran "Scenario: Greeting Alice"
    And it ran "Scenario: Greeting Bob"

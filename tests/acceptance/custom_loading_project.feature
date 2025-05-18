Feature: Testing a project with manual source loading

  This specification describes how to run tests for a project using manual source loading.

  Scenario: One feature file
    Given a file named "tests/test.feature" with
      """
      Feature: a feature
        Scenario: a scenario
          Given I calculate
          Then the result is 2
      """
    And a file named "src/calculate.R" with
      """
      calculate <- function(x) {
        x + 1
      }
      """
    And a file named "tests/steps.R" with
      """
      given("I calculate", function(context) {
        context$result <- calculate(1)
      })

      then("the result is {int}", function(n, context) {
        expect_equal(context$result, n)
      })
      """
    When I run
      """
      env <- new.env()
      source("tests/steps.R", local = env)
      source("src/calculate.R", local = env)
      test("tests", env = env)
      """
    Then it passes

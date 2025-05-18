Feature: Testing a {box} project

  Specification of how to run tests for a project using https://github.com/klmr/box.

  Scenario: One feature file
    Given a file named "tests/acceptance/box.feature" with
      """
      Feature: a feature
        Scenario: a scenario
          Given I calculate
          Then the result is 2
      """
    And a file named "src/calculate.R" with
      """
      #' @export
      calculate <- function(x) {
        x + 1
      }
      """
    And a file named "tests/acceptance/setup-steps.R" with
      """
      box::use(cucumber[given, when])
      box::use(../../src/calculate)

      given("I calculate", function(context) {
        context$result <- calculate$calculate(1)
      })

      then("the result is {int}", function(n, context) {
        expect_equal(context$result, n)
      })
      """
    When I run
      """
      box::purge_cache()
      test()
      """
    Then it passes

  Scenario: Two feature files
    Given a file named "tests/acceptance/box1.feature" with
      """
      Feature: Feature 1
        Scenario: Calculate 1
          Given I calculate1
          Then the result is 2
      """
    And a file named "tests/acceptance/box2.feature" with
      """
      Feature: Feature 2
        Scenario: Calculate 2
          Given I calculate2
          Then the result is 3
      """
    And a file named "src/calculate.R" with
      """
      #' @export
      calculate1 <- function(x) {
        x + 1
      }

      #' @export
      calculate2 <- function(x) {
        x + 2
      }
      """
    And a file named "tests/acceptance/setup-steps.R" with
      """
      box::use(cucumber[given, when])
      box::use(../../src/calculate[calculate1, calculate2])

      given("I calculate1", function(context) {
        context$result <- calculate1(1)
      })


      given("I calculate2", function(context) {
        context$result <- calculate2(1)
      })

      then("the result is {int}", function(n, context) {
        expect_equal(context$result, n)
      })
      """
    When I run
      """
      box::purge_cache()
      test()
      """
    Then it passes

Feature: Running scenarios alongside testthat tests
  `run()` in a `tests/testthat/test-*.R` file runs the feature files in `tests/testthat`
  as part of the package's testthat tests, e.g. with `testthat::test_local()` or `devtools::test()`.
  It takes the same arguments as `test()` to choose what to run.

  Background:
    Given a package
    And a file named "R/calculate.R" with
      """
      calculate <- function(x) x + 1
      """
    And a file named "tests/testthat/calculate.feature" with
      """
      Feature: Calculate
        Scenario: Adding one
          Given I calculate
          Then the result is 2
      """
    And a file named "tests/testthat/test-acceptance.R" with
      """
      run()
      """

  Scenario: Scenarios run with the package's testthat tests
    Given a file named "tests/testthat/setup-steps.R" with
      """
      given("I calculate", function(context) {
        context$result <- calculate(1)
      })
      then("the result is {int}", function(n, context) {
        expect_equal(context$result, n)
      })
      """
    And a file named "tests/testthat/test-calculate.R" with
      """
      test_that("calculate adds one", {
        expect_equal(calculate(1), 2)
      })
      """
    When I run
      """
      testthat::test_local()
      """
    Then it has 2 passed
    And it ran "Scenario: Adding one"
    And it ran "calculate adds one"

  Scenario: Step definitions outside setup files are loaded through testthat's env
    Given a file named "tests/testthat/steps/steps.R" with
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
      source("tests/testthat/steps/steps.R", local = env)
      testthat::test_local(env = env)
      """
    Then it passes

  Scenario: run() chooses feature files like test()
    Given a file named "tests/testthat/other.feature" with
      """
      Feature: Other
        Scenario: Not run
          Given I calculate
      """
    And a file named "tests/testthat/setup-steps.R" with
      """
      given("I calculate", function(context) {
        context$result <- calculate(1)
      })
      then("the result is {int}", function(n, context) {
        expect_equal(context$result, n)
      })
      """
    And a file named "tests/testthat/test-acceptance.R" with
      """
      run(filter = "calculate")
      """
    When I run
      """
      testthat::test_local()
      """
    Then only these scenarios ran:
      | scenario   |
      | Adding one |


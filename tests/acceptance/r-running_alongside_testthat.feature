@rd
Feature: Running scenarios alongside testthat tests
  `run()` in a `tests/testthat/test-*.R` file runs the feature files in `tests/testthat`
  as part of the package's testthat tests, e.g. with `testthat::test_local()` or `devtools::test()`.
  It chooses what to run like `test()`, with `filter`, `features`, `tags` and `name`.
  testthat's reporter reports each scenario as a test, and a failed step by its text.
  Pass a `reporter` to `run()` to report the run with cucumber's reporter too.

  `run()` isn't supported in a parallel testthat run, with `Config/testthat/parallel: true`: it's an error.

  `run()` can also run feature files outside of a testthat run, like in the console. Its step
  definitions and hooks are then cleared when it returns.

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
    Then it passes
    And it ran "Scenario: Adding one"
    And it ran "calculate adds one"

  Scenario: Step definitions sourced into an environment are passed with `test_local(env = )`
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

  Scenario Outline: run() chooses what to run like test(), with <argument>
    Given a file named "tests/testthat/other.feature" with
      """
      Feature: Other
        @slow
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
      run(<argument> = "<value>")
      """
    When I run
      """
      testthat::test_local()
      """
    Then only these scenarios ran:
      | scenario   |
      | Adding one |

    Examples:
      | argument | value             |
      | filter   | calculate         |
      | features | calculate.feature |
      | tags     | not @slow         |
      | name     | Adding one        |

  Scenario: testthat's reporter shows the step that failed
    Given a file named "tests/testthat/setup-steps.R" with
      """
      given("I calculate", function(context) {
        context$result <- calculate(1)
      })
      then("the result is {int}", function(n, context) {
        expect_equal(context$result, 3)
      })
      """
    When I run
      """
      testthat::test_local(reporter = "summary", stop_on_failure = FALSE)
      """
    Then the output includes 'Step "the result is 2" failed'
    And the output doesn't include "1 scenario"

  Scenario: run() runs outside of a testthat run
    Given a file named "features/calculate.feature" with
      """
      Feature: Calculate
        Scenario: Adding one
          Then one plus one is 2
      """
    And a file named "features/steps.R" with
      """
      then("one plus one is {int}", function(n, context) {
        expect_equal(1 + 1, n)
      })
      """
    When I run outside of a testthat run
      """
      source("features/steps.R")
      run("features", reporter = CucumberSummaryReporter$new())
      run("features", reporter = CucumberSummaryReporter$new(), strict = FALSE)
      """
    Then the output includes lines matching these patterns in order:
      """
      1 scenario \(1 passed\)
      1 scenario \(1 undefined\)
      """

  Scenario: run() in a parallel testthat run is an error
    When I run
      """
      withr::with_envvar(
        c(TESTTHAT_IS_PARALLEL = "true"),
        testthat::test_local(reporter = "summary", stop_on_failure = FALSE)
      )
      """
    Then the output includes "`run()` isn't supported in a parallel testthat run."

  Scenario: test() in a testthat file keeps the step definitions of the testthat run
    Given a file named "tests/testthat/setup-steps.R" with
      """
      given("I calculate", function(context) {
        context$result <- calculate(1)
      })
      then("the result is {int}", function(n, context) {
        expect_equal(context$result, n)
      })
      """
    And a file named "tests/acceptance/calculate.feature" with
      """
      Feature: Calculate
        Scenario: Adding one in tests/acceptance
          Given I add one to 1
          Then I get 2
      """
    And a file named "tests/acceptance/setup-steps.R" with
      """
      given("I add one to {int}", function(n, context) {
        context$result <- calculate(n)
      })
      then("I get {int}", function(n, context) {
        expect_equal(context$result, n)
      })
      """
    And a file named "tests/testthat/test-1-acceptance.R" with
      """
      cucumber::test("../acceptance", reporter = NULL)
      """
    When I run
      """
      testthat::test_local()
      """
    Then it passes
    And it ran "Scenario: Adding one"

Feature: Testing a package with cucumber tests in tests/testthat/ directory
  Scenario: One feature file
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "tests/testthat/package.feature" with
      """
      Feature: A package
        Scenario: A scenario
          Given a scenario step
          Then it has 1 steps
      """
    And a file named "tests/testthat/setup-steps.R" with
      """
      given("a scenario step", function(context) {
        context$steps <- context$steps %||% 0 + 1
      })

      then("it has {int} steps", function(n, context) {
        expect_equal(context$steps, n)
      })
      """
    And a file named "tests/testthat/test-acceptance.R" with
      """
      run()
      """
    When I run
      """
      testthat::test_local()
      """
    Then it passes

  Scenario: Multiple feature files
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "tests/testthat/test1.feature" with
      """
      Feature: a feature
        Scenario: a scenario
          Given a scenario step
          Given a scenario step
          Then it has 2 steps
      """
    And a file named "tests/testthat/test2.feature" with
      """
      Feature: another feature
        Scenario: another scenario
          Given another scenario step
          Then it has 1 steps
      """
    And a file named "tests/testthat/setup-steps.R" with
      """
      given("a scenario step", function(context) {
        context$steps <- context$steps %||% 0 + 1
      })

      given("another scenario step", function(context) {
        context$steps <- context$steps %||% 0 + 1
      })

      then("it has {int} steps", function(n, context) {
        expect_equal(context$steps, n)
      })
      """
    And a file named "tests/testthat/test-acceptance.R" with
      """
      run()
      """
    When I run
      """
      testthat::test_local()
      """
    Then it passes

  Scenario: Multiple feature files with a filter
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "tests/testthat/test1.feature" with
      """
      Feature: Feature 1
        Scenario: a scenario
          Given a scenario step
          Given a scenario step
          Then it has 2 steps
      """
    And a file named "tests/testthat/test2.feature" with
      """
      Feature: Feature 2
        Scenario: another scenario
          Given another scenario step
          Then it has 1 steps
      """
    And a file named "tests/testthat/setup-steps.R" with
      """
      given("a scenario step", function(context) {
        context$steps <- context$steps %||% 0 + 1
      })

      given("another scenario step", function(context) {
        context$steps <- context$steps %||% 0 + 1
      })

      then("it has {int} steps", function(n, context) {
        expect_equal(context$steps, n)
      })
      """
    And a file named "tests/testthat/test-acceptance.R" with
      """
      run(filter = "test1")
      """
    When I run
      """
      testthat::test_local()
      """
    Then it passes
    Then only "Feature 1" was run

  Scenario: No feature files
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "tests/testthat/setup-steps.R" with
      """
      given("a scenario step", function(context) {
        context$steps <- context$steps %||% 0 + 1
      })

      then("it has {int} steps", function(n, context) {
        expect_equal(context$steps, n)
      })
      """
    And a file named "tests/testthat/test-acceptance.R" with
      """
      run()
      """
    When I run
      """
      testthat::test_local(stop_on_failure = FALSE)
      """
    Then it has 1 errors

  Scenario: Source code is available in steps
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "tests/testthat/test.feature" with
      """
      Feature: a feature
        Scenario: a scenario
          Given I calculate
          Then the result is 2
      """
    And a file named "R/calculate.R" with
      """
      calculate <- function(x) {
        x + 1
      }
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
      run()
      """
    When I run
      """
      testthat::test_local()
      """
    Then it passes

  Scenario: Setup code is available in steps
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "tests/testthat/test.feature" with
      """
      Feature: a feature
        Scenario: a scenario
          Given I calculate
          Then the result is 2
      """
    And a file named "tests/testthat/setup-calculate.R" with
      """
      calculate <- function(x) {
        x + 1
      }
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
      run()
      """
    When I run
      """
      testthat::test_local()
      """

    Then it passes

  Scenario: Helper code is available in steps
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "tests/testthat/test.feature" with
      """
      Feature: a feature
        Scenario: a scenario
          Given I calculate
          Then the result is 2
      """
    And a file named "tests/testthat/helper-calculate.R" with
      """
      calculate <- function(x) {
        x + 1
      }
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
      run()
      """
    When I run
      """
      testthat::test_local()
      """
    Then it passes

  Scenario: Storing steps in custom directory
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "tests/testthat/test.feature" with
      """
      Feature: a feature
        Scenario: a scenario
          Given I calculate
          Then the result is 2
      """
    And a file named "R/calculate.R" with
      """
      calculate <- function(x) {
        x + 1
      }
      """
    And a file named "tests/testthat/steps/steps.R" with
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
      run()
      """
    When I run
      """
      env <- new.env()
      source("tests/testthat/steps/steps.R", local = env)
      testthat::test_local(env = env)
      """
    Then it passes

  Scenario: Testthat files alongside feature files
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "tests/testthat/test.feature" with
      """
      Feature: a feature
        Scenario: a scenario
          Given I calculate
          Then the result is 2
      """
    And a file named "R/calculate.R" with
      """
      calculate <- function(x) {
        x + 1
      }
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
      run()
      """
    And a file named "tests/testthat/test-calculate.R" with
      """
      test_that("calculate", {
        expect_equal(calculate(1), 2)
      })
      """
    When I run
      """
      testthat::test_local()
      """
    Then it has 2 passed

  Scenario: Registering hooks
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "tests/testthat/test.feature" with
      """
      Feature: a feature
        Scenario: a scenario
          Given I calculate
          Then the result is 2
      """
    And a file named "tests/testthat/setup-hooks.R" with
      """
      before(function(context, scenario_name) {
        context$before <- TRUE
      })

      after(function(context, scenario_name) {
        context$after <- TRUE
      })
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
      run()
      """
    And a file named "R/calculate.R" with
      """
      calculate <- function(x) {
        x + 1
      }
      """
    When I run
      """
      testthat::test_local()
      """
    Then it passes

  Scenario: Rerunning tests
    This scenario checks if users can run tests again after they have been run once.
    Each time hooks, parameters and steps are loaded from setup files, and cleaned up after each run.
    It's observed by tests not throwing errors.

    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "tests/testthat/test.feature" with
      """
      Feature: a feature
        Scenario: a scenario
          Given I calculate
          Then the result is 2
      """
    And a file named "tests/testthat/setup-hooks.R" with
      """
      before(function(context, scenario_name) {
        context$before <- TRUE
      })

      after(function(context, scenario_name) {
        context$after <- TRUE
      })
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
      run()
      """
    And a file named "R/calculate.R" with
      """
      calculate <- function(x) {
        x + 1
      }
      """
    When I run
      """
      testthat::test_local()
      testthat::test_local()
      """
    Then it passes

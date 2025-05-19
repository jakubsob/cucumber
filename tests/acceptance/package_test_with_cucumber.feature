Feature: Testing a package with cucumber tests in features/ directory
  Scenario: One feature file
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/package.feature" with
      """
      Feature: A package
        Scenario: A scenario
          Given a scenario step
          Then it has 1 steps
      """
    And a file named "features/setup-steps.R" with
      """
      given("a scenario step", function(context) {
        context$steps <- context$steps %||% 0 + 1
      })

      then("it has {int} steps", function(n, context) {
        expect_equal(context$steps, n)
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes

  Scenario: Multiple feature files
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/test1.feature" with
      """
      Feature: a feature
        Scenario: a scenario
          Given a scenario step
          Given a scenario step
          Then it has 2 steps
      """
    And a file named "features/test2.feature" with
      """
      Feature: another feature
        Scenario: another scenario
          Given another scenario step
          Then it has 1 steps
      """
    And a file named "features/setup-steps.R" with
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
    When I run
      """
      test("features")
      """
    Then it passes

  Scenario: Multiple feature files with filter
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/test1.feature" with
      """
      Feature: Feature 1
        Scenario: a scenario
          Given a scenario step
          Given a scenario step
          Then it has 2 steps
      """
    And a file named "features/test2.feature" with
      """
      Feature: Feature 2
        Scenario: another scenario
          Given another scenario step
          Then it has 1 steps
      """
    And a file named "features/setup-steps.R" with
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
    When I run
      """
      test("features", filter = "test1")
      """
    Then it passes
    Then only "Feature 1" was run

  Scenario: No feature files
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/setup-steps.R" with
      """
      given("a scenario step", function(context) {
        context$steps <- context$steps %||% 0 + 1
      })

      then("it has {int} steps", function(n, context) {
        expect_equal(context$steps, n)
      })
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 errors

  Scenario: Source code is available in steps
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/test.feature" with
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
    And a file named "features/setup-steps.R" with
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
      pkgload::load_all(quiet = TRUE)
      test("features")
      pkgload::unload()
      """
    Then it passes

  Scenario: Setup code is available in steps
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/test.feature" with
      """
      Feature: a feature
        Scenario: a scenario
          Given I calculate
          Then the result is 2
      """
    And a file named "features/setup-calculate.R" with
      """
      calculate <- function(x) {
        x + 1
      }
      """
    And a file named "features/setup-steps.R" with
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
      test("features")
      """

    Then it passes

  Scenario: Helper code is available in steps
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/test.feature" with
      """
      Feature: a feature
        Scenario: a scenario
          Given I calculate
          Then the result is 2
      """
    And a file named "features/helper-calculate.R" with
      """
      calculate <- function(x) {
        x + 1
      }
      """
    And a file named "features/setup-steps.R" with
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
      test("features")
      """
    Then it passes


  Scenario: Registering hooks
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/test.feature" with
      """
      Feature: a feature
        Scenario: a scenario
          Given I calculate
          Then the result is 2
      """
    And a file named "features/setup-hooks.R" with
      """
      before(function(context, scenario_name) {
        context$before <- TRUE
      })

      after(function(context, scenario_name) {
        context$after <- TRUE
      })
      """
    And a file named "features/setup-steps.R" with
      """
      given("I calculate", function(context) {
        context$result <- calculate(1)
      })

      then("the result is {int}", function(n, context) {
        expect_equal(context$result, n)
      })
      """
    And a file named "R/calculate.R" with
      """
      calculate <- function(x) {
        x + 1
      }
      """
    When I run
      """
      pkgload::load_all(quiet = TRUE)
      test("features")
      pkgload::unload(quiet = TRUE)
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
    And a file named "features/test.feature" with
      """
      Feature: a feature
        Scenario: a scenario
          Given I calculate
          Then the result is 2
      """
    And a file named "features/setup-hooks.R" with
      """
      before(function(context, scenario_name) {
        context$before <- TRUE
      })

      after(function(context, scenario_name) {
        context$after <- TRUE
      })
      """
    And a file named "features/setup-steps.R" with
      """
      given("I calculate", function(context) {
        context$result <- calculate(1)
      })

      then("the result is {int}", function(n, context) {
        expect_equal(context$result, n)
      })
      """
    And a file named "R/calculate.R" with
      """
      calculate <- function(x) {
        x + 1
      }
      """
    When I run
      """
      pkgload::load_all(quiet = TRUE)
      test("features")
      pkgload::unload(quiet = TRUE)

      pkgload::load_all(quiet = TRUE)
      test("features")
      pkgload::unload(quiet = TRUE)
      """
    Then it passes

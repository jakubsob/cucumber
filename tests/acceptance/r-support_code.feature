Feature: Loading step definitions and support code
  cucumber runs on testthat, so it loads files the way testthat does.
  Files named `setup-*.R` and `helper-*.R` next to the feature files are run before the scenarios:
  put step definitions, hooks and parameter types in them, along with any code the steps need.
  Code of the package under test is available once the package is loaded, e.g. with `pkgload::load_all()`.

  Background:
    Given a package
    And a file named "features/calculate.feature" with
      """
      Feature: Calculate
        Scenario: Adding one
          Given I calculate
          Then the result is 2
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

  @rd
  Scenario: Code in a setup file is available in steps
    Given a file named "features/setup-calculate.R" with
      """
      calculate <- function(x) x + 1
      """
    When I run
      """
      test("features")
      """
    Then it passes

  Scenario: Setup files use cucumber's functions without library(cucumber)
    `test()` attaches cucumber, like it attaches testthat for the steps' expectations.

    Given a file named "features/setup-calculate.R" with
      """
      calculate <- function(x) x + 1
      """
    And cucumber isn't attached
    When I run
      """
      test("features")
      """
    Then it passes

  Scenario: Code in a helper file is available in steps
    Given a file named "features/helper-calculate.R" with
      """
      calculate <- function(x) x + 1
      """
    When I run
      """
      test("features")
      """
    Then it passes

  @rd
  Scenario: Code of the loaded package is available in steps
    Given a file named "R/calculate.R" with
      """
      calculate <- function(x) x + 1
      """
    When I run
      """
      pkgload::load_all(quiet = TRUE)
      test("features")
      """
    Then it passes

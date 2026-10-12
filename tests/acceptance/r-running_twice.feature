Feature: Running tests more than once
  Step definitions, hooks and parameter types are registered when the setup files are loaded,
  and cleared when the run ends. Running the tests again in the same R session registers them anew,
  instead of making every step ambiguous.

  Scenario: Tests can be run twice in the same session
    Given a package
    And a file named "features/calculate.feature" with
      """
      Feature: Calculate
        Scenario: Adding one
          Given I calculate 1
          Then the result is 2
      """
    And a file named "features/setup-steps.R" with
      """
      define_parameter_type(name = "number", regexp = "\\d+", transformer = as.numeric)
      before(function(context, scenario) context$add <- (context$add %||% 0) + 1)
      given("I calculate {number}", function(x, context) {
        context$result <- x + context$add
      })
      then("the result is {int}", function(n, context) {
        expect_equal(context$result, n)
      })
      """
    When I run
      """
      test("features")
      test("features")
      """
    Then it passes
    And the output includes
      """
      Feature: Calculate
        Scenario: Adding one
          v Given I calculate 1
          v Then the result is 2


      --------------------------------------------------------------------------------
      Summary
        1 scenario (1 passed)
        2 steps (2 passed)
      --------------------------------------------------------------------------------

      Feature: Calculate
        Scenario: Adding one
          v Given I calculate 1
          v Then the result is 2


      --------------------------------------------------------------------------------
      Summary
        1 scenario (1 passed)
        2 steps (2 passed)
      --------------------------------------------------------------------------------
      """

  Scenario: Testthat tests with run() can be run twice in the same session
    Given a package
    And a file named "tests/testthat/calculate.feature" with
      """
      Feature: Calculate
        Scenario: Adding one
          Given I calculate 1
          Then the result is 2
      """
    And a file named "tests/testthat/setup-hooks.R" with
      """
      before(function(context, scenario) context$add <- (context$add %||% 0) + 1)
      """
    And a file named "tests/testthat/setup-steps.R" with
      """
      define_parameter_type(name = "number", regexp = "\\d+", transformer = as.numeric)
      given("I calculate {number}", function(x, context) {
        context$result <- x + context$add
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
      testthat::test_local()
      """
    Then it passes

  Scenario: Step definitions don't outlive the run that loaded them
    Given a package
    And a file named "features/calculate.feature" with
      """
      Feature: Calculate
        Scenario: Adding one
          Given I calculate 1
      """
    And a file named "features/setup-steps.R" with
      """
      given("I calculate {int}", function(x, context) {})
      """
    When I run
      """
      test("features")
      file.remove("features/setup-steps.R")
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 failed
    And the output includes
      """
      U Given I calculate 1
      """

@rd
Feature: Dots reporter
  `CucumberDotsReporter` prints one character for each step and hook as it finishes: `.` passed, `F` failed, `-` skipped, `P` pending,
  `U` undefined and `A` ambiguous. At the end it prints the summary of the run with the
  scenarios that didn't pass.

  Background:
    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
          When I add 1 item
          Then the basket has 1 item

        Scenario: Remove an item
          Given an empty basket
          When I remove 1 item
          Then the basket has 0 items
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) context$items <- 0)
      when("I add {int} item", function(n, context) context$items <- context$items + n)
      when("I remove {int} item", function(n, context) {
        if (context$items < n) stop("The basket is empty")
        context$items <- context$items - n
      })
      then("the basket has {int} item(s)", function(n, context) expect_equal(context$items, n))
      """

  Scenario: Each step is printed as a character
    When I run
      """
      test("features", reporter = CucumberDotsReporter$new(), stop_on_failure = FALSE)
      """
    Then the output includes
      """
      ....F-
      """
    And the output includes
      """
      2 scenarios (1 failed, 1 passed)
      6 steps (1 failed, 1 skipped, 4 passed)
      """

  Scenario: The scenarios that didn't pass are printed at the end
    When I run
      """
      test("features", reporter = CucumberDotsReporter$new(), stop_on_failure = FALSE)
      """
    Then the output includes
      """
      Failures

      Feature: Basket
      Scenario: Remove an item
      v Given an empty basket
      x When I remove 1 item
      """
    And the output includes "The basket is empty"
    And the output doesn't include "Scenario: Add an item"

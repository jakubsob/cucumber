@rd
Feature: Progress reporter
  `CucumberProgressReporter` is the default reporter. Like testthat's `ProgressReporter`, it prints
  one line for each feature, with its scenarios counted by status: failed (F), pending (P),
  undefined (U), skipped (S) and passed (OK). A scenario that didn't pass is printed as soon as
  it finishes, and again in the summary at the end.

  Background:
    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
          When I add 1 item

        Scenario: Remove an item
          Given an empty basket
          When I remove 1 item

        Scenario: Pay for the items
          Given an empty basket
          When I pay
      """
    And a file named "features/checkout.feature" with
      """
      Feature: Checkout
        Scenario: Check out an empty basket
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {})
      when("I add {int} item", function(n, context) {})
      when("I remove {int} item", function(n, context) stop("The basket is empty"))
      """

  Scenario: Each feature is a line with its scenarios counted by status
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the output includes
      """
      |  F  P  U  S  OK | Feature
      """
    And the output includes
      """
      x |  1     1      1 | Basket
      """
    And the output includes
      """
      v |               1 | Checkout
      """

  Scenario: A scenario that didn't pass is printed when it finishes
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the output includes
      """
      Feature: Basket
      Scenario: Remove an item
      v Given an empty basket
      x When I remove 1 item
      """
    And the output includes
      """
      Scenario: Pay for the items
      v Given an empty basket
      U When I pay
      """
    And the output includes
      """
      4 scenarios (1 failed, 1 undefined, 2 passed)
      """

  Scenario: The error that stopped the run is printed
    Given a file named "features/setup-steps.R" with
      """
      before_all(function() stop("the server didn't start"))
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the output includes
      """
      Error:
      the server didn't start
      """
    And the output includes
      """
      0 scenarios
      """

@rd
Feature: Progress reporter
  `CucumberProgressReporter` is the default reporter. Like testthat's `ProgressReporter`, it prints
  one line for each feature, with its scenarios counted by status: failed (F), pending (P),
  undefined (U), skipped (S) and passed (OK). An ambiguous scenario counts as failed. A feature that
  took a second or more shows how long it took. A scenario that didn't pass is printed as soon as
  it finishes, and again in the summary at the end.
  In a terminal that can redraw a line, a feature's line is redrawn with a spinner after each step.
  Elsewhere, like in CI, it's printed once the feature finishes.

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

  Scenario: A scenario that didn't pass is printed before its feature's line, and again in the summary
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the output includes these lines in order:
      """
      Scenario: Remove an item
      x When I remove 1 item
      x |  1     1      1 | Basket
      Failures:
      1) Scenario: Remove an item # basket.feature:6
      x When I remove 1 item
      """
    And the output includes "x When I remove 1 item" 2 times

  Scenario: A warning is printed as it's raised
    Given a file named "features/setup-hooks.R" with
      """
      before(function(context, scenario) {
        if (scenario$name == "Add an item") warning("The shop is busy")
      })
      """
    When I run it and it fails
      """
      test("features")
      """
    Then the output includes
      """
      Warning:
      The shop is busy
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
      Hook `before_all()` failed
      i Hook defined at: setup-steps.R:1
      Caused by error:
      ! the server didn't start
      """
    And the output includes
      """
      0 scenarios
      """

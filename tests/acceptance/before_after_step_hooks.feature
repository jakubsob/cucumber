Feature: Step hooks
  `before_step()` and `after_step()` run code before and after each step.
  They get the step, and after step hooks also get its result.

  Background:
    Given a package

  Scenario: Step hooks run around each step and after step hooks get its result
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
          When I add an item
          Then the basket has 1 item
      """
    And a file named "features/setup-steps.R" with
      """
      before_step(function(context, step) cat("before:", step$keyword, step$text, "\n"))
      after_step(function(context, step) cat("after:", step$text, step$status, "\n"))
      given("an empty basket", function(context) {})
      when("I add an item", function(context) stop("basket is full"))
      then("the basket has {int} item", function(n, context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 errors
    And the output includes
      """
      before: Given an empty basket
      after: an empty basket passed
      v Given an empty basket
      before: When I add an item
      after: I add an item failed
      x When I add an item
      """
    And the output doesn't include "before: Then the basket has 1 item"
    And the output doesn't include "after: the basket has 1 item"

  Scenario: A failing step hook fails the step
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      after_step(function(context, step) stop("step left a mess"))
      given("an empty basket", function(context) {})
      when("I add an item", function(context) stop("this step must not execute"))
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 errors
    And the error message includes "step left a mess"
    And the output includes
      """
      1 scenario (1 failed)
      2 steps (1 failed, 1 skipped)
      """

Feature: Step hooks
  `before_step()` and `after_step()` run code before and after each step.
  They get the step, and after step hooks also get its result.
  They don't run for skipped, undefined or ambiguous steps. A failing step hook fails the step.

  Background:
    Given a package

  @rd
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
    Then the output includes
      """
      before: Given an empty basket
      after: an empty basket passed
      before: When I add an item
      after: I add an item failed
      """
    And the steps have these results:
      | step                       | status  |
      | Given an empty basket      | passed  |
      | When I add an item         | failed  |
      | Then the basket has 1 item | skipped |
    And the output doesn't include "before: Then the basket has 1 item"
    And the output doesn't include "after: the basket has 1 item"

  @rd
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
    Then the error message includes "step left a mess"
    And the steps have these results:
      | step                  | status  |
      | Given an empty basket | failed  |
      | When I add an item    | skipped |

  Scenario: A step hook can't skip the scenario
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      before_step(function(context, step) skip_scenario("The shop is closed"))
      when("I add an item", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the steps have these results:
      | step               | status |
      | When I add an item | failed |
    And the error message includes "`skip_scenario()` can only be called in a `before()` or `after()` hook or a step."

  Scenario: A failing after step hook fails a pending step
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      after_step(function(context, step) stop("step left a mess"))
      given("an empty basket", function(context) pending())
      """
    When I run
      """
      test("features", strict = FALSE, stop_on_failure = FALSE)
      """
    Then it has 1 failed
    And the error message includes "step left a mess"
    And the steps have these results:
      | step                  | status |
      | Given an empty basket | failed |

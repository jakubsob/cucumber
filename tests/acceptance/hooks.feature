Feature: Hooks
  Hooks run code before and after each scenario, each step, or the whole run.
  Define as many as you need: before hooks run in the order they are defined,
  after hooks in the reverse order.

  Background:
    Given a package

  Scenario: Before hooks run in definition order and after hooks in reverse order
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) cat("before 1\n"))
      before(function(context, scenario) cat("before 2\n"))
      after(function(context, scenario) cat("after 1\n"))
      after(function(context, scenario) cat("after 2\n"))
      given("an empty basket", function(context) cat("step\n"))
      """
    When I run
      """
      test("features")
      """
    Then it has 0 errors
    And the output includes
      """
      before 1
      before 2
      step
      v Given an empty basket
      after 2
      after 1
      """

  Scenario: Hooks get the scenario, and after hooks get its result
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        @smoke
        Scenario: Add an item
          Given an empty basket
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) {
        cat("before:", scenario$name, scenario$tags, basename(scenario$uri), "\n")
      })
      after(function(context, scenario) {
        cat("after:", scenario$status, conditionMessage(scenario$error), "\n")
      })
      given("an empty basket", function(context) {})
      when("I add an item", function(context) stop("basket is full"))
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 errors
    And the output includes
      """
      before: Add an item @smoke basket.feature
      """
    And the output includes "after: failed"
    And the output includes "basket is full"

  Scenario: Tagged hooks run only for scenarios that match the tag expression
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        @db
        Scenario: Save the basket
          Given an empty basket

        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) cat("connect for", scenario$name, "\n"), tags = "@db")
      after(function(context, scenario) cat("disconnect for", scenario$name, "\n"), tags = "@db")
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features")
      """
    Then it has 0 errors
    And the output includes "connect for Save the basket"
    And the output includes "disconnect for Save the basket"
    And the output doesn't include "connect for Add an item"

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
    And the output doesn't include "the basket has 1 item passed"

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

  Scenario: Before all and after all hooks run once for the whole run
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket

        Scenario: Remove an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before_all(function() cat("start the server\n"))
      after_all(function() cat("stop the server\n"))
      before(function(context, scenario) cat("scenario\n"))
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features")
      """
    Then it has 0 errors
    And the output includes "start the server" once
    And the output includes "stop the server" once

  Scenario: A named hook's errors start with its name
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Save the basket
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) stop("connection refused"), name = "Connect to the database")
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 errors
    And the error message includes "Hook \"Connect to the database\" failed: connection refused"

  Scenario: A before hook skips the scenario with skip_scenario()
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        @api
        Scenario: Sync the basket
          Given an empty basket
          When I sync the basket

        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) skip_scenario("the API is down"), tags = "@api")
      before(function(context, scenario) cat("this hook must not run for", scenario$name, "\n"), tags = "@api")
      after(function(context, scenario) cat("after:", scenario$name, scenario$status, "\n"))
      given("an empty basket", function(context) {})
      when("I sync the basket", function(context) stop("this step must not execute"))
      """
    When I run
      """
      test("features")
      """
    Then it has 0 errors
    And the scenario "Sync the basket" is skipped with "Reason: the API is down"
    And the output includes
      """
      Scenario: Sync the basket
        - Given an empty basket
        - When I sync the basket
      after: Sync the basket skipped
      Scenario: Add an item
        v Given an empty basket
      after: Add an item passed
      """
    And the output doesn't include "this hook must not run"
    And the output includes
      """
      2 scenarios (1 skipped, 1 passed)
      3 steps (2 skipped, 1 passed)
      """

  Scenario Outline: A before hook makes the scenario pending with pending(), strict = <strict>
    A pending scenario fails the run only in strict mode, like a pending step.

    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Sync the basket
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) pending("the API client isn't written yet"))
      after(function(context, scenario) cat("after:", scenario$name, scenario$status, "\n"))
      given("an empty basket", function(context) stop("this step must not execute"))
      """
    When I run
      """
      test("features", strict = <strict>, stop_on_failure = FALSE)
      """
    Then the scenario "Sync the basket" is <outcome> with "<message>"
    And the output includes
      """
      Scenario: Sync the basket
        - Given an empty basket
      after: Sync the basket pending
      """
    And the output includes
      """
      1 scenario (1 pending)
      1 step (1 skipped)
      """

    Examples:
      | strict | outcome | message                                                   |
      | TRUE   | failed  | Hook is pending: the API client isn't written yet         |
      | FALSE  | skipped | Reason: Hook is pending: the API client isn't written yet |

  Scenario: skip_scenario() fails in hooks other than before hooks
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      after(function(context, scenario) skip_scenario("too late"))
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 errors
    And the error message includes "`skip_scenario()` can only be called in a `before()` hook or a step."

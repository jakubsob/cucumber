Feature: Step results
  Every step gets a result: passed, failed, pending, undefined, ambiguous or skipped.
  When a step doesn't pass, the rest of the scenario's steps are skipped,
  and the other scenarios still run.

  Background:
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """

  Scenario: Steps after a failing step are skipped
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
      given("an empty basket", function(context) {})
      when("I add an item", function(context) {
        expect_equal(1, 2)
      })
      then("the basket has {int} item", function(n, context) {
        stop("this step must not execute")
      })
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 failed
    And it has 0 errors
    And the output includes
      """
      - Then the basket has 1 item
      """
    And the output includes
      """
      1 scenario (1 failed)
      3 steps (1 failed, 1 skipped, 1 passed)
      """

  Scenario: An undefined step doesn't stop the run
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
          When I add an item
          Then the basket has 1 item

        Scenario: Look into the basket
          Given an empty basket
      """
    And a file named "features/checkout.feature" with
      """
      Feature: Checkout
        Scenario: Pay
          When I pay 5 euro
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it ran "Scenario: Pay"
    And it has 3 failed
    And the output includes
      """
      U When I add an item
      """
    And the output includes
      """
      U Then the basket has 1 item
      """
    And the output includes
      """
      when("I pay {int} euro", function(int, context) {
      """
    And the output includes
      """
      3 scenarios (2 undefined, 1 passed)
      5 steps (3 undefined, 2 passed)
      """

  Scenario: An undefined step skips the scenario when not strict
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features", strict = FALSE)
      """
    Then it has 1 skipped
    And it has 0 failed

  Scenario: An ambiguous step fails the scenario even when not strict
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      when("I add an item", function(context) {})
      when("I add an {word}", function(thing, context) {})
      """
    When I run
      """
      test("features", strict = FALSE, stop_on_failure = FALSE)
      """
    Then it has 1 failed
    And the output includes
      """
      A When I add an item
      """

  Scenario: A failing before hook skips the steps and fails the scenario
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario_name) {
        stop("no database")
      })
      given("an empty basket", function(context) {
        stop("this step must not execute")
      })
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 errors
    And the error message includes "no database"
    And the output includes
      """
      - Given an empty basket
      """
    And the output includes
      """
      1 scenario (1 failed)
      1 step (1 skipped)
      """

  Scenario: A failing after hook fails the scenario
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      after(function(context, scenario_name) {
        stop("can't close the database")
      })
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 errors
    And the output includes
      """
      1 scenario (1 failed)
      1 step (1 passed)
      """

Feature: Step results
  Every step gets a result: passed, failed, pending, undefined, ambiguous or skipped.
  When a step doesn't pass, the rest of the scenario's steps are skipped,
  and the other scenarios still run.

  Background:
    Given a package

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

  Scenario: A scenario whose steps pass without expectations passes
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {
        context$basket <- list()
      })
      when("I add an item", function(context) {
        context$basket <- c(context$basket, "item")
      })
      """
    When I run
      """
      test("features", reporter = testthat::ListReporter$new())
      """
    Then it passes
    And it has 1 passed
    And it has 0 skipped

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

  Scenario: A step skips the scenario with skip_scenario()
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Sync the basket
          Given an empty basket
          When I sync the basket
          Then the basket is synced
      """
    And a file named "features/setup-steps.R" with
      """
      after(function(context, scenario) cat("after:", scenario$name, scenario$status, "\n"))
      given("an empty basket", function(context) {})
      when("I sync the basket", function(context) skip_scenario("the API is down"))
      then("the basket is synced", function(context) stop("this step must not execute"))
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
        v Given an empty basket
        - When I sync the basket
          Reason: the API is down
        - Then the basket is synced
      after: Sync the basket skipped
      """
    And the output includes
      """
      1 scenario (1 skipped)
      3 steps (2 skipped, 1 passed)
      """

  Scenario: testthat::skip() in a step skips the scenario
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Sync the basket
          When I sync the basket
          Then the basket is synced
      """
    And a file named "features/setup-steps.R" with
      """
      after(function(context, scenario) cat("after:", scenario$name, scenario$status, "\n"))
      when("I sync the basket", function(context) testthat::skip("the API is down"))
      then("the basket is synced", function(context) stop("this step must not execute"))
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
        - When I sync the basket
          Reason: the API is down
        - Then the basket is synced
      after: Sync the basket skipped
      """

  Scenario Outline: A step definition with the wrong number of arguments fails the step, <case>
    A step definition gets the step's parameters, then its data table or doc string, then `context`.

    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add items
          When I add 3 items
            | name  |
            | apple |
      """
    And a file named "features/setup-steps.R" with
      """
      when("I add {int} items", <definition>)
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 errors
    And the error message includes "<message>"
    And the error message includes "Use `function(int, dataTable, context)`."

    Examples:
      | case                 | definition                               | message                                                    |
      | missing parameter    | function(context) {}                    | The step definition has 1 argument, but the step passes 3.  |
      | missing data table   | function(n, context) {}                 | The step definition has 2 arguments, but the step passes 3. |
      | extra argument       | function(n, table, extra, context) {}   | The step definition has 4 arguments, but the step passes 3. |

  Scenario: A step definition with `...` gets any number of arguments
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add items
          When I add 3 items
      """
    And a file named "features/setup-steps.R" with
      """
      when("I add {int} items", function(..., context) {
        expect_equal(list(...), list(3L))
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes

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

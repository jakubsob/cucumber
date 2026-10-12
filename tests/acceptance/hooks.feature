Feature: Hooks
  `before()` and `after()` run code before and after each scenario, like opening and closing a connection.
  Define as many as you need: before hooks run in the order they are defined,
  after hooks in the reverse order. Give a hook a `name` to find it in error messages.

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
    And the output includes
      """
      after: failed Step "I add an item" failed
      """

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
    Then it has 1 failed
    And the error message includes "Hook \"Connect to the database\" failed: connection refused"

  Scenario: A failing before hook skips the steps and fails the scenario
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) {
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
    Then it has 1 failed
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
      after(function(context, scenario) {
        stop("can't close the database")
      })
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 failed
    And the output includes "can't close the database" once
    And the output includes
      """
      1 scenario (1 failed)
      1 step (1 passed)
      """

  Scenario: A failing after hook is reported after a failing step
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      after(function(context, scenario) stop("can't close the database"))
      given("an empty basket", function(context) stop("basket is broken"))
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the output includes
      """
      ! basket is broken
      Error:
      can't close the database
      """

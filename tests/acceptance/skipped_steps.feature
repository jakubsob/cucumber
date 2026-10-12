Feature: Skipped steps
  Call `skip_scenario()` in a step or a `before()` hook to skip the rest of the scenario,
  for example when a service it needs is down. The skip reason is reported, and after hooks still run.

  Background:
    Given a package

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

  Scenario: skip_scenario() in an after hook is an error
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
    Then it has 1 failed
    And the error message includes "`skip_scenario()` can only be called in a `before()` hook or a step."

  Rule: testthat::skip() also skips the scenario

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

    Scenario: testthat::skip() in a before hook skips the scenario
      Given a file named "features/basket.feature" with
        """
        Feature: Basket
          Scenario: Sync the basket
            When I sync the basket
        """
      And a file named "features/setup-steps.R" with
        """
        before(function(context, scenario) testthat::skip("the API is down"))
        after(function(context, scenario) cat("after:", scenario$name, scenario$status, "\n"))
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
          - When I sync the basket
        after: Sync the basket skipped
        """
      And the output includes
        """
        1 scenario (1 skipped)
        """

    Scenario: testthat::skip() in an after hook is an error
      Given a file named "features/basket.feature" with
        """
        Feature: Basket
          Scenario: Add an item
            Given an empty basket
        """
      And a file named "features/setup-steps.R" with
        """
        after(function(context, scenario) cat("this hook still runs\n"))
        after(function(context, scenario) testthat::skip("too late"))
        given("an empty basket", function(context) {})
        """
      When I run
        """
        test("features", stop_on_failure = FALSE)
        """
      Then it has 1 failed
      And the error message includes "`testthat::skip()` can only be called in a `before()` hook or a step."
      And the output includes "this hook still runs"

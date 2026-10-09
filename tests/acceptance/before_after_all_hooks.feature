Feature: Before all and after all hooks
  `before_all()` and `after_all()` run code once, before the first scenario and after the last one,
  like starting and stopping a server.
  A failing `before_all()` hook stops the run before any scenario. `after_all()` hooks run even when the run failed,
  and a failing one fails the run.

  Background:
    Given a package

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
    Then it passes
    And the output includes "start the server" once
    And the output includes "stop the server" once
    And the output includes
      """
      start the server

      Feature: Basket
      """
    And the output includes
      """
      scenario
      v Given an empty basket

      stop the server
      """

  Scenario: Before all hooks run in definition order and after all hooks in reverse order
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before_all(function() cat("before all 1\n"))
      before_all(function() cat("before all 2\n"))
      after_all(function() cat("after all 1\n"))
      after_all(function() cat("after all 2\n"))
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features")
      """
    Then it passes
    And the output includes
      """
      before all 1
      before all 2
      """
    And the output includes
      """
      after all 2
      after all 1
      """

  Rule: A failing before all or after all hook fails the run

    Background:
      Given a file named "features/basket.feature" with
        """
        Feature: Basket
          Scenario: Add an item
            Given an empty basket

          Scenario: Remove an item
            Given an empty basket
        """

    Scenario: A failing before all hook stops the run before any scenario, and after all hooks still run
      Given a file named "features/setup-steps.R" with
        """
        before_all(function() stop("the server didn't start"))
        after_all(function() cat("stop the server\n"))
        given("an empty basket", function(context) stop("this step must not execute"))
        """
      When I run
        """
        test("features", stop_on_failure = FALSE)
        """
      Then it has 1 errors
      And it has 0 passed
      And the error message includes "the server didn't start"
      And the output includes "stop the server" once
      And the output includes
        """
        0 scenarios
        """

    Scenario: A failing after all hook fails the run after every scenario has run
      Given a file named "features/setup-steps.R" with
        """
        after_all(function() stop("the server didn't stop"))
        given("an empty basket", function(context) {})
        """
      When I run
        """
        test("features", stop_on_failure = FALSE)
        """
      Then it has 1 errors
      And only these scenarios ran:
        | scenario       |
        | Add an item    |
        | Remove an item |
      And it has 2 passed
      And the error message includes "the server didn't stop"

    Scenario: After all hooks run when scenarios fail
      Given a file named "features/setup-steps.R" with
        """
        after_all(function() cat("stop the server\n"))
        given("an empty basket", function(context) stop("basket is broken"))
        """
      When I run
        """
        test("features", stop_on_failure = FALSE)
        """
      Then it has 2 failed
      And the output includes "stop the server" once

    Scenario: A named before all hook's error starts with its name
      Given a file named "features/setup-steps.R" with
        """
        before_all(function() stop("connection refused"), name = "Start the server")
        given("an empty basket", function(context) {})
        """
      When I run
        """
        test("features", stop_on_failure = FALSE)
        """
      Then it has 1 errors
      And the error message includes "Hook \"Start the server\" failed: connection refused"

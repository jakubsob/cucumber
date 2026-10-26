Feature: Before all and after all hooks
  `before_all()` and `after_all()` run code once, before the first scenario and after the last one,
  like starting and stopping a server. They take no arguments, or a `context` to attach data to the report,
  which isn't shared with the scenarios.
  A failing `before_all()` hook stops the run before any scenario, after the other `before_all()` hooks ran.
  `after_all()` hooks run even when the run failed, and a failing one fails the run.

  Background:
    Given a package

  @rd
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
    And the output includes these lines in order:
      """
      start the server
      scenario
      scenario
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
      Then the errors are
        """
        [error]
        Error: Hook `before_all()` failed
        i Hook defined at: setup-steps.R:1
        Caused by error:
        ! the server didn't start
        """
      And the output includes "stop the server" once
      And no scenario ran

    Scenario: The before all hooks after a failing one still run
      Given a file named "features/setup-steps.R" with
        """
        before_all(function() stop("the server didn't start"))
        before_all(function() cat("start the database\n"))
        given("an empty basket", function(context) stop("this step must not execute"))
        """
      When I run
        """
        test("features", stop_on_failure = FALSE)
        """
      Then the errors are
        """
        [error]
        Error: Hook `before_all()` failed
        i Hook defined at: setup-steps.R:1
        Caused by error:
        ! the server didn't start
        """
      And the output includes "start the database" once

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
      Then only these scenarios ran:
        | scenario       |
        | Add an item    |
        | Remove an item |
      And the errors are
        """
        [error]
        Error: Hook `after_all()` failed
        i Hook defined at: setup-steps.R:1
        Caused by error:
        ! the server didn't stop
        """

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
      Then the scenarios have these results:
        | scenario       | status |
        | Add an item    | failed |
        | Remove an item | failed |
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
      Then the errors are
        """
        [error]
        Error: Hook "Start the server" failed
        i Hook defined at: setup-steps.R:1
        Caused by error:
        ! connection refused
        """

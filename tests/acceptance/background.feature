Feature: Background

  Background allows you to add some context to the scenarios in a single feature.
  A Background is much like a scenario containing a number of steps.
  The difference is when it is run.
  The background is run before each of your scenarios but after any of your `before` hooks.

  Scenario: One scenario and a background
    Given a file named "tests/acceptance/background.feature" with
      """
      Feature: a feature
        Background:
          Given a background step

        Scenario: a scenario
          When a scenario step
          Then it has 3 steps
      """
    And a file named "tests/acceptance/setup-steps.R" with
      """
      given("a background step", function(context) {
        context$steps <- context$steps %||% 1 + 1
      })

      when("a scenario step", function(context) {
        context$steps <- context$steps %||% 1 + 1
      })

      then("it has {int} steps", function(n, context) {
        expect_equal(context$steps, n)
      })
      """
    When I run cucumber
    Then it passes

  Scenario: Two scenarios and a background
    Given a file named "tests/acceptance/background.feature" with
      """
      Feature: a feature
        Background:
          Given a background step

        Scenario: a scenario
          When a scenario step
          Then it has 3 steps

        Scenario: another scenario
          When another scenario step
          Then it has 3 steps
      """
    And a file named "tests/acceptance/setup-steps.R" with
      """
      given("a background step", function(context) {
        context$steps <- context$steps %||% 1 + 1
      })

      when("a scenario step", function(context) {
        context$steps <- context$steps %||% 1 + 1
      })

      when("another scenario step", function(context) {
        context$steps <- context$steps %||% 1 + 1
      })

      then("it has {int} steps", function(n, context) {
        expect_equal(context$steps, n)
      })
      """
    When I run cucumber
    Then it passes

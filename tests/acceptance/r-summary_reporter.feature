@rd
Feature: Summary reporter
  `CucumberSummaryReporter` prints only the summary of the run: the scenarios that didn't pass, numbered
  and with where they are, then the scenarios and steps counted by status and how long the run took.
  Scenarios that failed, are ambiguous or undefined are Failures. Pending scenarios, and failed attempts of
  retried scenarios, are Warnings.

  Scenario: Only the summary is printed
    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
          When I add 1 item

        Scenario: Remove an item
          Given an empty basket
          When I remove 1 item
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {})
      when("I add {int} item", function(n, context) {})
      when("I remove {int} item", function(n, context) stop("The basket is empty"))
      """
    When I run
      """
      test("features", reporter = CucumberSummaryReporter$new(), stop_on_failure = FALSE)
      """
    Then the output includes
      """
      Failures:

      1) Scenario: Remove an item # basket.feature:6
      v Given an empty basket
      x When I remove 1 item
      """
    And the output includes these lines in order:
      """
      x When I remove 1 item
      Summary
      2 scenarios (1 failed, 1 passed)
      4 steps (1 failed, 3 passed)
      """
    And the output doesn't include "Scenario: Add an item"
    And the output doesn't include "Feature: Basket"
    And the output doesn't include "...."

  Scenario: Pending scenarios and failed attempts that were retried are warnings
    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Pay
          Given I pay

        Scenario: Sync
          When I sync
      """
    And a file named "features/setup-steps.R" with
      """
      attempts <- 0
      given("I pay", function(context) pending())
      when("I sync", function(context) {
        attempts <<- attempts + 1
        if (attempts == 1) stop("The server is busy")
      })
      """
    When I run
      """
      test("features", reporter = CucumberSummaryReporter$new(), retry = 1, stop_on_failure = FALSE)
      """
    Then the output includes these lines in order:
      """
      Warnings:
      1) Scenario: Pay # basket.feature:2
      P Given I pay
      2) Scenario: Sync (attempt 1, retried) # basket.feature:5
      x When I sync
      Summary
      2 scenarios (1 pending, 1 passed)
      """
    And the output doesn't include "Failures:"

  Scenario: The summary ends with how long the run took, and how long its steps took
    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Wait for the basket
          When I wait
      """
    And a file named "features/setup-steps.R" with
      """
      when("I wait", function(context) Sys.sleep(0.2))
      """
    When I run
      """
      test("features", reporter = CucumberSummaryReporter$new())
      """
    Then the output includes lines matching these patterns in order:
      """
      ^1 step \(1 passed\)$
      ^0m00\.[2-9][0-9]{2}s \(executing steps: 0m00\.[2-9][0-9]{2}s\)$
      """

  Scenario: A run without scenarios counts no scenarios and no steps
    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
      """
    When I run
      """
      test("features", reporter = CucumberSummaryReporter$new())
      """
    Then the output includes
      """
      Summary
      0 scenarios
      0 steps
      """

  Scenario: A hook's error is printed in the summary where the hook ran
    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) stop("The shop is closed"))
      after(function(context, scenario) stop("The till is broken"))
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features", reporter = CucumberSummaryReporter$new(), stop_on_failure = FALSE)
      """
    Then the output includes these lines in order:
      """
      Failures:
      1) Scenario: Add an item # basket.feature:2
      Hook `before()` failed
      ! The shop is closed
      - Given an empty basket
      Hook `after()` failed
      ! The till is broken
      """

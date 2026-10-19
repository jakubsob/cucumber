@rd
Feature: Summary reporter
  `CucumberSummaryReporter` prints only the summary of the run: the scenarios and steps counted by status, and the scenarios that didn't pass.

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
      Summary
      2 scenarios (1 failed, 1 passed)
      4 steps (1 failed, 3 passed)
      """
    And the output includes
      """
      Failures

      Feature: Basket
      Scenario: Remove an item
      v Given an empty basket
      x When I remove 1 item
      """
    And the output doesn't include "Scenario: Add an item"
    And the output doesn't include "...."

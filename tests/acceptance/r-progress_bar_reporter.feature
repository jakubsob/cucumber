Feature: Progress bar reporter
  `CucumberProgressBarReporter` shows a bar of the steps and hooks run so far, like the
  `progress-bar` formatter of cucumber-js. A scenario that didn't pass is printed as soon
  as it finishes. The bar is drawn only in a terminal that can redraw a line.

  Background:
    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Remove an item
          Given an empty basket
          When I remove 1 item

        Scenario: Add an item
          Given an empty basket
          When I add 1 item
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {})
      when("I add {int} item", function(n, context) {})
      when("I remove {int} item", function(n, context) stop("The basket is empty"))
      """

  Scenario: The bar counts the steps run
    When I run
      """
      reporter <- withr::with_options(list(cli.dynamic = TRUE), CucumberProgressBarReporter$new())
      test("features", reporter = reporter, stop_on_failure = FALSE)
      """
    Then the output includes "1/4 steps ["
    And the output includes "4/4 steps ["

  Scenario: A scenario that didn't pass is printed when it finishes
    When I run
      """
      test("features", reporter = CucumberProgressBarReporter$new(), stop_on_failure = FALSE)
      """
    Then the output includes
      """
      Feature: Basket
      Scenario: Remove an item
      v Given an empty basket
      x When I remove 1 item
      """
    And the output includes "The basket is empty"
    And the output doesn't include "Scenario: Add an item"
    And the output doesn't include "steps ["
    And the output includes
      """
      2 scenarios (1 failed, 1 passed)
      4 steps (1 failed, 3 passed)
      """

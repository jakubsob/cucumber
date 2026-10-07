Feature: Dry run
  A dry run matches every step to a step definition, but runs neither steps nor hooks.
  Use it to find undefined and ambiguous steps without running the scenarios.

  Scenario: A dry run doesn't run steps or hooks
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario_name) {
        stop("hooks must not run")
      })
      given("an empty basket", function(context) {
        stop("steps must not run")
      })
      when("I add an item", function(context) {
        stop("steps must not run")
      })
      """
    When I run
      """
      test("features", dry_run = TRUE)
      """
    Then it has 0 errors
    And it has 0 failed
    And the output includes
      """
      - Given an empty basket
      - When I add an item
      """
    And the output includes
      """
      1 scenario (1 skipped)
      2 steps (2 skipped)
      """

  Scenario: A dry run reports undefined steps
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      """
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {
        stop("steps must not run")
      })
      """
    When I run
      """
      test("features", dry_run = TRUE, stop_on_failure = FALSE)
      """
    Then it has 1 failed
    And it has 0 errors
    And the output includes
      """
      - Given an empty basket
      U When I add an item
      """
    And the output includes
      """
      when("I add an item", function(context) {
      """

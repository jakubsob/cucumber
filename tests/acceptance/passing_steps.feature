Feature: Passing steps
  A step passes when its step definition returns without an error.
  A scenario passes when all its steps pass, even if they have no expectations.

  Background:
    Given a package

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
      test("features", reporter = NULL)
      """
    Then it passes
    And it has 1 passed
    And it has 0 skipped

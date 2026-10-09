Feature: Undefined steps
  A step that matches no step definition is undefined.
  It's reported with a snippet of the missing step definition, and the other scenarios still run.

  Background:
    Given a package

  Scenario: An undefined step doesn't stop the run
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
          When I add an item
          Then the basket has 1 item

        Scenario: Look into the basket
          Given an empty basket
      """
    And a file named "features/checkout.feature" with
      """
      Feature: Checkout
        Scenario: Pay
          When I pay 5 euro
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it ran "Scenario: Pay"
    And it has 2 failed
    And the output includes
      """
      U When I add an item
      """
    And the output includes
      """
      U Then the basket has 1 item
      """
    And the output includes
      """
      when("I pay {int} euro", function(int, context) {
      """
    And the output includes
      """
      3 scenarios (2 undefined, 1 passed)
      5 steps (3 undefined, 2 passed)
      """

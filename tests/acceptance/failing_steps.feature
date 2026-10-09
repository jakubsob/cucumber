Feature: Failing steps
  A step fails when its step definition throws an error or a failed expectation.
  The steps after it are skipped, and the other scenarios still run.

  Background:
    Given a package

  Scenario: Steps after a failing step are skipped
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
          When I add an item
          Then the basket has 1 item
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {})
      when("I add an item", function(context) {
        expect_equal(1, 2)
      })
      then("the basket has {int} item", function(n, context) {
        stop("this step must not execute")
      })
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 failed
    And the output includes
      """
      - Then the basket has 1 item
      """
    And the output includes
      """
      1 scenario (1 failed)
      3 steps (1 failed, 1 skipped, 1 passed)
      """

  Scenario: A step that throws an error fails, and the other scenarios still run
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          When I add an item

        Scenario: Look into the basket
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {})
      when("I add an item", function(context) {
        stop("basket is full")
      })
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then it has 1 failed
    And it has 1 passed
    And the error message includes "basket is full"
    And the output includes
      """
      2 scenarios (1 failed, 1 passed)
      """

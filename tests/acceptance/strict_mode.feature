Feature: Strict mode
  By default, pending and undefined steps fail the run.
  With `strict = FALSE` they skip their scenario instead. Ambiguous steps fail either way.

  Background:
    Given a package

  Scenario: A pending step skips the scenario when not strict
    Given a file named "features/mixed.feature" with
      """
      Feature: Mixed
        Scenario: Implemented
          Given I have 1
          Then I get 1

        Scenario: Not yet implemented
          Given a step that is pending
      """
    And a file named "features/setup-steps.R" with
      """
      given("I have {int}", function(n, context) {
        context$value <- n
      })
      then("I get {int}", function(n, context) {
        expect_equal(context$value, n)
      })
      given("a step that is pending", function(context) {
        pending()
      })
      """
    When I run
      """
      test("features", strict = FALSE)
      """
    Then it has 1 passed
    And it has 1 skipped
    And it has 0 failed

  Scenario: An undefined step skips the scenario when not strict
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features", strict = FALSE)
      """
    Then it has 1 skipped
    And it has 0 failed

  Scenario: An ambiguous step fails the scenario even when not strict
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      when("I add an item", function(context) {})
      when("I add an {word}", function(thing, context) {})
      """
    When I run
      """
      test("features", strict = FALSE, stop_on_failure = FALSE)
      """
    Then it has 1 failed
    And the steps have these results:
      | step               | status    |
      | When I add an item | ambiguous |

Feature: Tagged hooks
  A hook with `tags` runs only for the scenarios that match its tag expression,
  like `before(connect, tags = "@db")`.

  Background:
    Given a package

  @rd
  Scenario: Tagged hooks run only for scenarios that match the tag expression
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        @db
        Scenario: Save the basket
          Given an empty basket

        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) cat("connect for", scenario$name, "\n"), tags = "@db")
      after(function(context, scenario) cat("disconnect for", scenario$name, "\n"), tags = "@db")
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features")
      """
    Then it has 0 errors
    And the output includes "connect for Save the basket"
    And the output includes "disconnect for Save the basket"
    And the output doesn't include "connect for Add an item"
    And the output doesn't include "disconnect for Add an item"

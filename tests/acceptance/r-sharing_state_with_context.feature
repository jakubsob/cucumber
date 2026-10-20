@rd
Feature: Sharing state with context
  Every step definition and scenario hook gets `context`.
  It's an environment that steps and hooks of one scenario share.
  Each scenario starts with a new, empty `context`.

  Background:
    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          When I add an item
          Then the basket has 1 item

        Scenario: Look into the basket
          Then the basket has 0 items
      """

  Scenario: Steps of a scenario share context
    Given a file named "features/setup-steps.R" with
      """
      when("I add an item", function(context) {
        context$items <- c(context$items, "apple")
      })
      then("the basket has {int} item(s)", function(n, context) {
        expect_length(context$items, n)
      })
      """
    When I run
      """
      test("features")
      """
    Then the scenarios have these results:
      | scenario             | status |
      | Add an item          | passed |
      | Look into the basket | passed |

  Scenario: Hooks share context with the steps
    Given a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) {
        context$items <- character()
      })
      after(function(context, scenario) {
        cat(scenario$name, "ends with", length(context$items), "items\n")
      })
      when("I add an item", function(context) {
        context$items <- c(context$items, "apple")
      })
      then("the basket has {int} item(s)", function(n, context) {
        expect_length(context$items, n)
      })
      """
    When I run
      """
      test("features")
      """
    Then it passes
    And the output includes "Add an item ends with 1 items"
    And the output includes "Look into the basket ends with 0 items"

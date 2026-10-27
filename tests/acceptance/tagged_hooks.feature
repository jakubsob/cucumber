Feature: Tagged hooks
  A hook with `tags` runs only for the scenarios that match its tag expression,
  like `before(connect, tags = "@db")`. A step hook with `tags` runs only for the steps of those scenarios.

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
    Then it passes
    And the output includes "connect for Save the basket"
    And the output includes "disconnect for Save the basket"
    And the output doesn't include "connect for Add an item"
    And the output doesn't include "disconnect for Add an item"

  Scenario: A tagged hook runs for every scenario of a feature with the tag
    Scenarios inherit the tags of their feature, Rule and Examples.

    Given a file named "features/basket.feature" with
      """
      @db
      Feature: Basket
        Scenario: Save the basket
          Given an empty basket

        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) cat("connect for", scenario$name, "\n"), tags = "@db")
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features")
      """
    Then the output includes "connect for Save the basket"
    And the output includes "connect for Add an item"

  Scenario: A tagged hook runs for the scenarios of a Rule or of Examples with the tag
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        @db
        Rule: Saved baskets
          Scenario: Save the basket
            Given an empty basket

        Rule: Items
          Scenario Outline: Add <item>
            Given an empty basket

            @db
            Examples: Saved
              | item  |
              | apple |

            Examples: Not saved
              | item |
              | pear |
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) cat("connect for", scenario$name, "\n"), tags = "@db")
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features")
      """
    Then the output includes "connect for Save the basket"
    And the output includes "connect for Add apple"
    And the output doesn't include "connect for Add pear"

  Scenario Outline: A tagged <hook>() hook runs only for the steps of scenarios that match the tag expression
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
      <hook>(function(context, step) cat("<hook> for", step$text, "\n"), tags = "@db")
      before(function(context, scenario) cat("scenario", scenario$name, "\n"))
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features")
      """
    Then the output includes "<hook> for an empty basket" once
    And the output includes these lines in order:
      """
      scenario Save the basket
      <hook> for an empty basket
      scenario Add an item
      """

    Examples:
      | hook        |
      | before_step |
      | after_step  |

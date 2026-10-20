Feature: Rule
  A Rule groups scenarios that illustrate one business rule.
  A Rule can have its own Background, which runs after the Feature's Background.

  Scenario: Scenarios inside a Rule are run
    Given a package
    And a file named "features/rule.feature" with
      """
      Feature: Basket
        Rule: Items can be added
          Scenario: Add one item
            Given the basket has 0 items
            When I add 1 item
            Then the basket should have 1 items

        Rule: Items can be removed
          Example: Remove one item
            Given the basket has 2 items
            When I remove 1 item
            Then the basket should have 1 items
      """
    And a file named "features/setup-steps.R" with
      """
      given("the basket has {int} items", function(n, context) {
        context$items <- n
      })
      when("I add {int} item", function(n, context) {
        context$items <- context$items + n
      })
      when("I remove {int} item", function(n, context) {
        context$items <- context$items - n
      })
      then("the basket should have {int} items", function(n, context) {
        expect_equal(context$items, n)
      })
      """
    When I run
      """
      test("features")
      """
    Then the scenarios have these results:
      | scenario        | status |
      | Add one item    | passed |
      | Remove one item | passed |

  Scenario: A Rule Background runs after the Feature Background, only for its own scenarios
    Given a package
    And a file named "features/rule.feature" with
      """
      Feature: Basket
        Background:
          Given the basket has 0 items

        Scenario: Outside any rule
          Then the basket should have 0 items

        Rule: A full basket
          Background:
            When I add 5 item

          Scenario: Full basket
            Then the basket should have 5 items

          Scenario Outline: Removing from a full basket
            When I remove <n> item
            Then the basket should have <left> items

            Examples:
              | n | left |
              | 1 | 4    |
              | 2 | 3    |
      """
    And a file named "features/setup-steps.R" with
      """
      given("the basket has {int} items", function(n, context) {
        context$items <- n
      })
      when("I add {int} item", function(n, context) {
        context$items <- context$items + n
      })
      when("I remove {int} item", function(n, context) {
        context$items <- context$items - n
      })
      then("the basket should have {int} items", function(n, context) {
        expect_equal(context$items, n)
      })
      """
    When I run
      """
      test("features")
      """
    Then the scenarios have these results:
      | scenario                    | status |
      | Outside any rule            | passed |
      | Full basket                 | passed |
      | Removing from a full basket | passed |
      | Removing from a full basket | passed |

  Scenario: Rule tags are inherited by its scenarios
    Given a package
    And a file named "features/rule.feature" with
      """
      Feature: Basket
        @adding
        Rule: Items can be added
          Scenario: Add one item
            Given the basket has 0 items
            When I add 1 item
            Then the basket should have 1 items

        Rule: Items can be removed
          Scenario: Remove one item
            Given the basket has 2 items
            When I remove 1 item
            Then the basket should have 1 items
      """
    And a file named "features/setup-steps.R" with
      """
      given("the basket has {int} items", function(n, context) {
        context$items <- n
      })
      when("I add {int} item", function(n, context) {
        context$items <- context$items + n
      })
      when("I remove {int} item", function(n, context) {
        context$items <- context$items - n
      })
      then("the basket should have {int} items", function(n, context) {
        expect_equal(context$items, n)
      })
      """
    When I run
      """
      test("features", tags = "@adding")
      """
    Then only these scenarios ran:
      | scenario     |
      | Add one item |

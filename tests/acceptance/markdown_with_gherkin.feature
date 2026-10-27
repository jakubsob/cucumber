Feature: Markdown with Gherkin
  A `.feature.md` file is a Markdown document with Gherkin in it, which reads well wherever Markdown is
  rendered. Its headers are the Feature, Rule, Background, Scenario and Examples, its list items that start
  with a step keyword are steps, its code blocks are Doc Strings and its tables indented 2 to 5 spaces are
  Data Tables and Examples. Tags are in backticks. The rest of the Markdown is ignored.

  Background:
    Given a package

  @rd
  Scenario: A Markdown document runs like a feature file
    Given a file named "features/basket.feature.md" with
      """
      # Feature: Basket

      A basket holds the items a customer wants to buy.
      This table isn't Gherkin, because it isn't indented:

      | item  | price |
      | ----- | ----- |
      | apple | 1     |

      ## Scenario Outline: Add <n> apples

      * Given an empty basket
      * When I add <n> apples
      * Then the basket has <n> items

      ### Examples:

        | n |
        | - |
        | 1 |
        | 2 |
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {
        context$items <- 0
      })
      when("I add {int} apples", function(n, context) {
        context$items <- context$items + n
      })
      then("the basket has {int} items", function(n, context) {
        expect_equal(context$items, n)
      })
      """
    When I run
      """
      test("features")
      """
    Then the steps have these results:
      | scenario     | step                        | status |
      | Add 1 apples | Given an empty basket       | passed |
      | Add 1 apples | When I add 1 apples         | passed |
      | Add 1 apples | Then the basket has 1 items | passed |
      | Add 2 apples | Given an empty basket       | passed |
      | Add 2 apples | When I add 2 apples         | passed |
      | Add 2 apples | Then the basket has 2 items | passed |

  @rd
  Scenario: A code block is a Doc String and an indented table is a Data Table
    The separator row under the header of a Markdown table isn't a row of the Data Table.

    Given a file named "features/basket.feature.md" with
      """
      # Feature: Basket

      ## Scenario: Add items

      * Given these items:
        | item   | price |
        | ------ | ----: |
        | apple  | 1     |
        | banana | 2     |
      * When I add a note:
        ```json
        {"gift": true}
        ```
      """
    And a file named "features/setup-steps.R" with
      """
      given("these items:", function(table, context) {
        expect_equal(table$item, c("apple", "banana"))
      })
      when("I add a note:", function(note, context) {
        expect_equal(as.character(note), '{"gift": true}')
        expect_equal(attr(note, "media_type"), "json")
      })
      """
    When I run
      """
      test("features")
      """
    Then the steps have these results:
      | step               | status |
      | Given these items: | passed |
      | When I add a note: | passed |

  Scenario: Tags are written in backticks
    Given a file named "features/basket.feature.md" with
      """
      # Feature: Basket

      `@smoke`
      ## Scenario: Add an item

      * Given an empty basket

      ## Scenario: Remove an item

      * Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features", tags = "@smoke")
      """
    Then the scenarios have these results:
      | scenario    | status |
      | Add an item | passed |

  Scenario: Feature files and Markdown documents run together
    Given a file named "features/add.feature.md" with
      """
      # Feature: Add

      ## Scenario: Add an item

      * Given an empty basket
      """
    And a file named "features/remove.feature" with
      """
      Feature: Remove
        Scenario: Remove an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features", filter = "add|remove")
      """
    Then the scenarios have these results:
      | scenario       | status |
      | Add an item    | passed |
      | Remove an item | passed |

  Scenario: A Rule and a Background are headers too
    Given a file named "features/basket.feature.md" with
      """
      # Feature: Basket

      ## Background:

      * Given an empty basket

      ## Rule: Items are counted

      ### Background:

      * When I add 1 apples

      ### Scenario: Add an apple

      * Then the basket has 1 items
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {
        context$items <- 0
      })
      when("I add {int} apples", function(n, context) {
        context$items <- context$items + n
      })
      then("the basket has {int} items", function(n, context) {
        expect_equal(context$items, n)
      })
      """
    When I run
      """
      test("features")
      """
    Then the steps have these results:
      | scenario     | step                        | status |
      | Add an apple | Given an empty basket       | passed |
      | Add an apple | When I add 1 apples         | passed |
      | Add an apple | Then the basket has 1 items | passed |

  Scenario: The cucumber.language option sets the language of Markdown documents
    A Markdown document has no `# language:` line, as it would be a header.

    Given a file named "features/panier.feature.md" with
      """
      # Fonctionnalité: Panier

      ## Scénario: Ajouter une pomme

      * Soit un panier vide
      """
    And a file named "features/setup-steps.R" with
      """
      given("un panier vide", function(context) {})
      """
    When I run
      """
      withr::with_options(list(cucumber.language = "fr"), test("features"))
      """
    Then the steps have these results:
      | scenario          | step                | status |
      | Ajouter une pomme | Soit un panier vide | passed |

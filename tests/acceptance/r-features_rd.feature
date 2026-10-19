@rd
Feature: Scenarios as documentation
  `features_rd()` puts scenarios of feature files in the help page of a function, in a
  "Specification" section, so readers of the help find how it behaves. Call it with `@eval`
  in the function's roxygen block. It selects scenarios like `test()`: by `features` and their
  lines, `filter`, `name` and `tags`. By default only scenarios tagged `@rd` are selected,
  set the `cucumber.rd_tags` option to use another tag expression. Name the section with
  `section`, or for every help page with the `cucumber.rd_section` option.

  Background:
    Given a package
    And a file named "tests/acceptance/basket.feature" with
      """
      Feature: Basket
        A basket holds the items a customer wants to buy.

        Background:
          Given an empty basket

        @rd
        Scenario: Add an item
          When I add 1 item
          Then the basket has 1 item

        @example
        Scenario: Remove an item from an empty basket
          When I remove 1 item
          Then the basket is empty

        @rd
        Scenario Outline: Add items
          When I add <n> items
          Then the basket has <n> items

          Examples:
            | n |
            | 2 |
            | 3 |
      """

  Scenario: The scenarios tagged @rd are in the help page
    Given a file named "R/add.R" with
      """
      #' Add items to a basket
      #' @eval cucumber::features_rd()
      #' @export
      add <- function(basket, n) basket + n
      """
    When I run
      """
      roxygen2::roxygenise()
      """
    Then the help page "add" includes
      """
      Specification:

      Basket:

      A basket holds the items a customer wants to buy.

      Background:
        Given an empty basket

      Scenario: Add an item
        When I add 1 item
        Then the basket has 1 item

      Scenario Outline: Add items
        When I add <n> items
        Then the basket has <n> items

        Examples:
          | n |
          | 2 |
          | 3 |

      Source: 'tests/acceptance/basket.feature'
      """
    And the help page "add" doesn't include "Remove an item"
    And the help page "add" doesn't include "@rd"

  Scenario: The scenarios are in the pkgdown reference page
    They're Gherkin code blocks, like those of a Markdown page.

    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      Title: Example
      Description: An example.
      License: MIT
      Authors@R: person("Ada", "Lovelace", role = c("aut", "cre"))
      Encoding: UTF-8
      """
    And a file named "R/add.R" with
      """
      #' Add items to a basket
      #' @eval cucumber::features_rd(features = "basket.feature:8")
      #' @export
      add <- function(basket, n) basket + n
      """
    When I run
      """
      roxygen2::roxygenise()
      pkgdown::build_reference(".", topics = "add", preview = FALSE)
      """
    Then the reference page "add" has the Gherkin block
      """
      Scenario: Add an item
        When I add 1 item
        Then the basket has 1 item
      """

  Scenario: The blank lines of a scenario are kept in the pkgdown reference page
    Given a file named "DESCRIPTION" with
      """
      Package: example
      Version: 0.1.0
      Title: Example
      Description: An example.
      License: MIT
      Authors@R: person("Ada", "Lovelace", role = c("aut", "cre"))
      Encoding: UTF-8
      """
    And a file named "tests/acceptance/checkout.feature" with
      """
      Feature: Checkout
        @rd
        Scenario: Pay for the basket
          The customer pays for every item in the basket.

          Given a basket with 2 items
          When I pay
          Then the basket is empty
      """
    And a file named "R/add.R" with
      """
      #' Add items to a basket
      #' @eval cucumber::features_rd(features = "checkout.feature")
      #' @export
      add <- function(basket, n) basket + n
      """
    When I run
      """
      roxygen2::roxygenise()
      pkgdown::build_reference(".", topics = "add", preview = FALSE)
      """
    Then the reference page "add" has the Gherkin block
      """
      Scenario: Pay for the basket
        The customer pays for every item in the basket.

        Given a basket with 2 items
        When I pay
        Then the basket is empty
      """

  Scenario: A scenario selected by its line
    Given a file named "R/add.R" with
      """
      #' Add items to a basket
      #' @eval cucumber::features_rd(features = "basket.feature:8")
      #' @export
      add <- function(basket, n) basket + n
      """
    When I run
      """
      roxygen2::roxygenise()
      """
    Then the help page "add" includes "Scenario: Add an item"
    And the help page "add" doesn't include "Scenario Outline: Add items"

  Scenario: An example of an outline selected by the line of its row
    Given a file named "R/add.R" with
      """
      #' Add items to a basket
      #' @eval cucumber::features_rd(features = "basket.feature:25")
      #' @export
      add <- function(basket, n) basket + n
      """
    When I run
      """
      roxygen2::roxygenise()
      """
    Then the help page "add" includes
      """
      Scenario Outline: Add items
        When I add <n> items
        Then the basket has <n> items

        Examples:
          | n |
          | 3 |
      """
    And the help page "add" doesn't include "| 2 |"

  Scenario: Scenarios selected by name, whatever their tags
    Given a file named "R/remove.R" with
      """
      #' Remove items from a basket
      #' @eval cucumber::features_rd(name = "^Remove", tags = NULL)
      #' @export
      remove <- function(basket, n) basket - n
      """
    When I run
      """
      roxygen2::roxygenise()
      """
    Then the help page "remove" includes
      """
      Scenario: Remove an item from an empty basket
        When I remove 1 item
        Then the basket is empty
      """
    And the help page "remove" doesn't include "Scenario: Add an item"

  Scenario: Another tag marks the scenarios for documentation
    Given a file named "R/remove.R" with
      """
      #' Remove items from a basket
      #' @eval cucumber::features_rd()
      #' @export
      remove <- function(basket, n) basket - n
      """
    When I run
      """
      withr::with_options(list(cucumber.rd_tags = "@example"), roxygen2::roxygenise())
      """
    Then the help page "remove" includes "Scenario: Remove an item from an empty basket"
    And the help page "remove" doesn't include "Scenario: Add an item"

  Scenario: The section has another name
    Given a file named "R/add.R" with
      """
      #' Add items to a basket
      #' @eval cucumber::features_rd(features = "basket.feature:8", section = "Examples of use")
      #' @export
      add <- function(basket, n) basket + n
      """
    When I run
      """
      roxygen2::roxygenise()
      """
    Then the help page "add" includes "Examples of use:"
    And the help page "add" doesn't include "Specification:"

  Scenario: The sections of every help page have another name
    Given a file named "R/add.R" with
      """
      #' Add items to a basket
      #' @eval cucumber::features_rd(features = "basket.feature:8")
      #' @export
      add <- function(basket, n) basket + n
      """
    When I run
      """
      withr::with_options(list(cucumber.rd_section = "Behavior"), roxygen2::roxygenise())
      """
    Then the help page "add" includes "Behavior:"
    And the help page "add" doesn't include "Specification:"

  Scenario: Scenarios of a Rule are under the Rule
    Only the selected Examples of a Scenario Outline are shown, and only the Rules with
    selected scenarios.

    Given a file named "tests/acceptance/discounts.feature" with
      """
      Feature: Discounts

        Rule: Orders over 100 get 10% off

          Scenario Outline: Discount of an order
            When I order for <total>
            Then I pay <paid>

            @rd
            Examples: Discounted
              | total | paid |
              | 200   | 180  |

            Examples: Not discounted
              | total | paid |
              | 100   | 100  |

        Rule: Members get free shipping

          Scenario: A member orders
            When a member orders
            Then shipping is free
      """
    And a file named "R/discount.R" with
      """
      #' Discount an order
      #' @eval cucumber::features_rd(features = "discounts.feature")
      #' @export
      discount <- function(total) total
      """
    When I run
      """
      roxygen2::roxygenise()
      """
    Then the help page "discount" includes
      """
      Discounts:

      *Rule: Orders over 100 get 10% off*

      Scenario Outline: Discount of an order
        When I order for <total>
        Then I pay <paid>

        Examples: Discounted
          | total | paid |
          | 200   | 180  |

      Source: 'tests/acceptance/discounts.feature'
      """
    And the help page "discount" doesn't include "Not discounted"
    And the help page "discount" doesn't include "Members get free shipping"

  Scenario: A selection without scenarios is an error
    When I run it and it fails
      """
      cucumber::features_rd(features = "basket.feature:13")
      """
    Then it fails with "No scenarios to document."

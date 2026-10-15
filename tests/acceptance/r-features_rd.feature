@rd
Feature: Scenarios as documentation
  `features_rd()` puts scenarios of feature files in the help page of a function, in a
  "Specification" section, so readers of the help find how it behaves. Call it with `@eval`
  in the function's roxygen block. It selects scenarios like `test()`: by `features` and their
  lines, `filter`, `name` and `tags`. By default only scenarios tagged `@rd` are selected,
  set the `cucumber.rd_tags` option to use another tag expression.

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
    Then the reference page "add" includes
      """
      Scenario: Add an item
        When I add 1 item
        Then the basket has 1 item
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

  Scenario: A selection without scenarios is an error
    When I run it and it fails
      """
      cucumber::features_rd(features = "basket.feature:13")
      """
    Then it fails with "No scenarios to document."

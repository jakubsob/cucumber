@rd
Feature: Scenarios as documentation
  `features_rd()` puts scenarios of feature files in the help page of a function, in a
  "Behavior" section, so readers of the help find how it behaves. Call it with `@eval`
  in the function's roxygen block. It selects scenarios like `test()`: by `features` and their
  lines, `filter`, `name` and `tags`. By default only scenarios tagged `@rd` are selected,
  set the `cucumber.rd_tags` option to use another tag expression. Name the section with
  `section`, or for every help page with the `cucumber.rd_section` option.

  In the help page, each feature is one block of Gherkin, as it's written. On HTML pages, like
  the pkgdown reference page, it's shown like Markdown with Gherkin: its name and the names of
  its Rules, Backgrounds, scenarios and Examples are headers, its steps a list, its tables tables
  and its Doc Strings code, a Doc String of Gherkin highlighted. With `markdown = FALSE`, HTML
  pages show the block of Gherkin too.

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
      Behavior:

      Feature: Basket
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

  Scenario: A feature is Markdown in the pkgdown reference page
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
      #' @eval cucumber::features_rd()
      #' @export
      add <- function(basket, n) basket + n
      """
    When I run
      """
      roxygen2::roxygenise()
      pkgdown::build_reference(".", topics = "add", preview = FALSE)
      """
    Then the reference page "add" has the headings
      """
      Feature: Basket
      Background:
      Scenario: Add an item
      Scenario Outline: Add items
      Examples:
      """
    And the reference page "add" has the steps
      """
      Given an empty basket
      When I add 1 item
      Then the basket has 1 item
      When I add <n> items
      Then the basket has <n> items
      """
    And the reference page "add" has the table
      | n |
      | 2 |
      | 3 |

  Scenario: A feature is one Gherkin code block in the pkgdown reference page with markdown = FALSE
    The block has the feature's name and description, the Background and the selected
    scenarios, like a code block of a Markdown page.

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
      #' @eval cucumber::features_rd(features = "basket.feature:8", markdown = FALSE)
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
      Feature: Basket
        A basket holds the items a customer wants to buy.

        Background:
          Given an empty basket

        Scenario: Add an item
          When I add 1 item
          Then the basket has 1 item
      """

  Scenario: The blank lines of a scenario are kept in the pkgdown reference page with markdown = FALSE
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
      #' @eval cucumber::features_rd(features = "checkout.feature", markdown = FALSE)
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
      Feature: Checkout

        Scenario: Pay for the basket
          The customer pays for every item in the basket.

          Given a basket with 2 items
          When I pay
          Then the basket is empty
      """

  Scenario: The scenarios are highlighted in the pkgdown reference page with markdown = FALSE
    Their tokens have the classes pandoc gives tokens, so that the site's theme colours them
    like other code, without a script.

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
    And a file named "tests/acceptance/greeting.feature" with
      """
      Feature: Greeting
        @rd
        Scenario Outline: Greet a customer
          # The customer gives their name
          Given a customer named "<name>"
          When I greet them with
            ```
            Hello!
            ```
          Then they reply

          Examples:
            | name |
            | Ada  |
      """
    And a file named "R/greet.R" with
      """
      #' Greet a customer
      #' @eval cucumber::features_rd(features = "greeting.feature", markdown = FALSE)
      #' @export
      greet <- function(name) paste("Hello", name)
      """
    When I run
      """
      roxygen2::roxygenise()
      pkgdown::build_reference(".", topics = "greet", preview = FALSE)
      """
    Then the reference page "greet" highlights the Gherkin
      | token                           | class |
      | Scenario Outline:               | kw    |
      | Examples:                       | kw    |
      | Given                           | fu    |
      | When                            | fu    |
      | # The customer gives their name | co    |
      | "<name>"                        | st    |
      | <name>                          | va    |
      | Hello!                          | st    |
      | \|                              | op    |

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

  Scenario: Scenarios selected by name, whatever their tags, with tags = NULL
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

  Scenario: Scenarios of the feature files whose name matches a filter
    Given a file named "tests/acceptance/checkout.feature" with
      """
      Feature: Checkout
        @rd
        Scenario: Pay for the basket
          When I pay
      """
    And a file named "R/add.R" with
      """
      #' Add items to a basket
      #' @eval cucumber::features_rd(filter = "^basket$")
      #' @export
      add <- function(basket, n) basket + n
      """
    When I run
      """
      roxygen2::roxygenise()
      """
    Then the help page "add" includes "Scenario: Add an item"
    And the help page "add" doesn't include "Scenario: Pay for the basket"

  Scenario: Only the selected Examples of a Scenario Outline are shown, without their tags
    Given a file named "tests/acceptance/checkout.feature" with
      """
      Feature: Checkout
        Scenario Outline: Pay with <card>
          When I pay with <card>

          @rd
          Examples: Cards
            | card |
            | Visa |

          Examples: Vouchers
            | card    |
            | voucher |
      """
    And a file named "R/pay.R" with
      """
      #' Pay for a basket
      #' @eval cucumber::features_rd(features = "checkout.feature")
      #' @export
      pay <- function(basket) basket
      """
    When I run
      """
      roxygen2::roxygenise()
      """
    Then the help page "pay" includes
      """
      Scenario Outline: Pay with <card>
        When I pay with <card>

        Examples: Cards
          | card |
          | Visa |
      """
    And the help page "pay" doesn't include "Vouchers"
    And the help page "pay" doesn't include "@rd"

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
    And the help page "add" doesn't include "Behavior:"

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
      withr::with_options(list(cucumber.rd_section = "Specification"), roxygen2::roxygenise())
      """
    Then the help page "add" includes "Specification:"
    And the help page "add" doesn't include "Behavior:"

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
      Feature: Discounts

        Rule: Orders over 100 get 10% off

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

  Scenario: Code between backticks is shown as written
    roxygen doesn't evaluate it as inline R code.

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
    And a file named "tests/acceptance/calculator.feature" with
      """
      Feature: Calculator
        @rd
        Scenario: Evaluate an expression
          When I evaluate `r 1 + 1`
          Then the result is 2
      """
    And a file named "R/calculate.R" with
      """
      #' Evaluate an expression
      #' @eval cucumber::features_rd(features = "calculator.feature")
      #' @export
      calculate <- function(expression) eval(parse(text = expression))
      """
    When I run
      """
      roxygen2::roxygenise()
      pkgdown::build_reference(".", topics = "calculate", preview = FALSE)
      """
    Then the help page "calculate" includes "When I evaluate `r 1 + 1`"
    And the reference page "calculate" has the steps
      """
      When I evaluate r 1 + 1
      Then the result is 2
      """

  Scenario: Scenarios with characters of more than one byte are shown as written
    Given a file named "tests/acceptance/prices.feature" with
      """
      Feature: Prices
        Prices are in pounds.

        @rd
        Scenario: A price in pounds
          Given a price of £430
          Then the price is £430
      """
    And a file named "R/price.R" with
      """
      #' Price an item
      #' @eval cucumber::features_rd(features = "prices.feature")
      #' @export
      price <- function(x) x
      """
    When I run
      """
      roxygen2::roxygenise()
      """
    Then the help page "price" includes
      """
      Prices are in pounds.

      Scenario: A price in pounds
        Given a price of £430
        Then the price is £430
      """

  Scenario: Names and descriptions of features and Rules are shown as written
    Given a file named "tests/acceptance/discounts.feature" with
      """
      Feature: Discounts of {percent}%
        A discount is {percent}% of the total, a `{float}`.

        Rule: {int} items get 10% off
          Each {item} counts, a `{word}`.

          @rd
          Scenario: Order 3 items
            When I order 3 items
            Then I get 10% off
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
      Feature: Discounts of {percent}%
        A discount is {percent}% of the total, a `{float}`.

        Rule: {int} items get 10% off
          Each {item} counts, a `{word}`.
      """

  Scenario: Scenarios of Markdown with Gherkin are in the help page as they are written
    Given a file named "tests/acceptance/checkout.feature.md" with
      """
      # Feature: Checkout

      `@rd`
      ## Scenario: Pay for the basket

      * Given a basket with 2 items
      * When I pay
      * Then the basket is empty
      """
    And a file named "R/pay.R" with
      """
      #' Pay for a basket
      #' @eval cucumber::features_rd(features = "checkout.feature.md")
      #' @export
      pay <- function(basket) basket
      """
    When I run
      """
      roxygen2::roxygenise()
      """
    Then the help page "pay" includes
      """
      # Feature: Checkout

      ## Scenario: Pay for the basket

      * Given a basket with 2 items
      * When I pay
      * Then the basket is empty
      """

  Scenario: Scenarios of Markdown with Gherkin are highlighted in the pkgdown reference page with markdown = FALSE
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
    And a file named "tests/acceptance/checkout.feature.md" with
      """
      # Feature: Checkout

      `@rd`
      ## Scenario Outline: Pay with <card>

      * Given a basket with 2 items
      * When I pay with "<card>"

      ### Examples:

        | card |
        | ---- |
        | visa |
      """
    And a file named "R/pay.R" with
      """
      #' Pay for a basket
      #' @eval cucumber::features_rd(features = "checkout.feature.md", markdown = FALSE)
      #' @export
      pay <- function(basket) basket
      """
    When I run
      """
      roxygen2::roxygenise()
      pkgdown::build_reference(".", topics = "pay", preview = FALSE)
      """
    Then the reference page "pay" highlights the Gherkin
      | token             | class |
      | Scenario Outline: | kw    |
      | Examples:         | kw    |
      | Given             | fu    |
      | When              | fu    |
      | "<card>"          | st    |
      | \|                | op    |

  Scenario: A Doc String of Gherkin is highlighted Gherkin, another one a code block of its media type
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
    And a file named "tests/acceptance/documentation.feature" with
      ```
      Feature: Documentation
        @rd
        Scenario: Document a feature
          Given a file named "basket.feature" with
            """
            Feature: Basket
              Scenario: Add an item
                Given an empty basket
            """
          And a file named "steps.R" with
            """r
            given("an empty basket", function(context) NULL)
            """
      ```
    And a file named "R/document.R" with
      """
      #' Document a feature
      #' @eval cucumber::features_rd(features = "documentation.feature")
      #' @export
      document <- function(feature) feature
      """
    When I run
      """
      roxygen2::roxygenise()
      pkgdown::build_reference(".", topics = "document", preview = FALSE)
      """
    Then the reference page "document" has the Gherkin block
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And the reference page "document" highlights the Gherkin
      | token     | class |
      | Feature:  | kw    |
      | Scenario: | kw    |
      | Given     | fu    |
    And the help page "document" includes
      """
      given("an empty basket", function(context) NULL)
      """

  Scenario: A cell of a table is on one line in the pkgdown reference page
    Its new lines are shown as `\n`, like in Gherkin.

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
    And a file named "tests/acceptance/links.feature" with
      """
      Feature: Links
        @rd
        Scenario: Links
          Then the links are:
            | links          | separator |
            | a.com\nb.com   | \|        |
      """
    And a file named "R/link.R" with
      """
      #' Link pages
      #' @eval cucumber::features_rd(features = "links.feature")
      #' @export
      link <- function(url) url
      """
    When I run
      """
      roxygen2::roxygenise()
      pkgdown::build_reference(".", topics = "link", preview = FALSE)
      """
    Then the reference page "link" has the table
      | links         | separator |
      | a.com\\nb.com | \|        |

  Scenario: A selection of scenarios that aren't tagged is an error
    When I run it and it fails
      """
      cucumber::features_rd(features = "basket.feature:13")
      """
    Then it fails with
      """
      Error:
      ! No scenarios to document.
      i Tag the scenarios with `@rd`, or select them whatever their tags with `tags = NULL`.
      """

  Scenario: A selection without scenarios is an error
    When I run it and it fails
      """
      cucumber::features_rd(features = "basket.feature:14", tags = NULL)
      """
    Then it fails with
      """
      Error:
      ! No scenarios to document.
      i Select scenarios with `features`, `filter` or `name`.
      """

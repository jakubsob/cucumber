@rd
Feature: Sharing state with context
  Every step definition and scenario hook gets `context`.
  It's an environment that steps and hooks of one scenario share.
  Each scenario starts with a new, empty `context`.

  Code a step or a hook defers in `context` runs when the scenario ends, after its `after()` hooks,
  like code deferred in a testthat test runs when the test ends. Pass `context` to `withr::defer()`
  or to a `local_*()` function, like `withr::local_options(.local_envir = context)` or
  `testthat::local_mocked_bindings(.env = context)`, to undo what a step changes when its scenario ends.
  Without it, the change is undone when the step ends. An error of the deferred code is a warning of the
  scenario, as its steps already have their results.

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

  Scenario: A printed context shows what steps and hooks put in it, and its methods
    Given a file named "features/setup-steps.R" with
      """
      when("I add an item", function(context) {
        context$items <- c("apple", "pear")
        context$total <- 2
        print(context)
      })
      then("the basket has {int} item(s)", function(n, context) {})
      """
    When I run
      """
      test("features", filter = "basket", name = "Add an item")
      """
    Then the output includes these lines in order:
      """
      <context>
      items: chr [1:2] "apple" "pear"
      total: num 2
      Methods:
      attach(data, media_type = NULL, file_name = NULL): attach a string or a raw vector to the report
      log(text): attach text to the report
      link(...): attach one or more URLs to the report
      """

  Scenario: A printed context shows its first 10 items and how many more there are
    Given a file named "features/setup-steps.R" with
      """
      when("I add an item", function(context) {
        for (i in 1:12) assign(sprintf("item_%02d", i), i, envir = context)
        print(context)
        print(context, n = 12)
      })
      then("the basket has {int} item(s)", function(n, context) {})
      """
    When I run
      """
      test("features", filter = "basket", name = "Add an item")
      """
    Then the output includes these lines in order:
      """
      <context>
      item_10: int 10
      # i 2 more items
      # i Use `print(n = ...)` to see more items
      Methods:
      <context>
      item_12: int 12
      Methods:
      """

  Scenario: What a step defers in context runs when the scenario ends
    Given a file named "features/setup-steps.R" with
      """
      when("I add an item", function(context) {
        withr::local_options(basket.items = 1, .local_envir = context)
      })
      then("the basket has {int} item(s)", function(n, context) {
        expect_equal(getOption("basket.items", 0), n)
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

  Scenario: What steps and hooks defer in context runs after the after hooks
    Like `withr::defer()`, what was deferred last runs first.

    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) {
        withr::defer(cat("deferred by the before hook\n"), envir = context)
      })
      after(function(context, scenario) cat("after hook\n"))
      when("I add an item", function(context) {
        withr::defer(cat("deferred by the step\n"), envir = context)
      })
      """
    When I run
      """
      test("features")
      """
    Then the output includes these lines in order:
      """
      after hook
      deferred by the step
      deferred by the before hook
      """

  Scenario: What a step changes without context is undone when the step ends
    Given a file named "features/setup-steps.R" with
      """
      when("I add an item", function(context) {
        withr::local_options(basket.items = 1)
      })
      then("the basket has {int} item(s)", function(n, context) {
        expect_equal(getOption("basket.items", 0), n)
      })
      """
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item for a moment
          When I add an item
          Then the basket has 0 items
      """
    When I run
      """
      test("features")
      """
    Then the scenarios have these results:
      | scenario                 | status |
      | Add an item for a moment | passed |

  Scenario: A function a step mocks in context stays mocked until the scenario ends
    Given a file named "R/stock.R" with
      """
      in_stock <- function() FALSE
      """
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Apples are delivered
          When the apples are delivered
          Then apples are in stock

        Scenario: Apples aren't delivered
          Then apples aren't in stock
      """
    And a file named "features/setup-steps.R" with
      """
      when("the apples are delivered", function(context) {
        testthat::local_mocked_bindings(in_stock = function() TRUE, .env = context)
      })
      then("apples are in stock", function(context) {
        expect_true(in_stock())
      })
      then("apples aren't in stock", function(context) {
        expect_false(in_stock())
      })
      """
    When I run
      """
      pkgload::load_all(quiet = TRUE)
      test("features")
      """
    Then the scenarios have these results:
      | scenario                | status |
      | Apples are delivered    | passed |
      | Apples aren't delivered | passed |

  Scenario: An error of what a step deferred in context is a warning of its scenario
    Given a file named "features/setup-steps.R" with
      """
      when("I add an item", function(context) {
        withr::defer(stop("The basket is gone"), envir = context)
      })
      then("the basket has {int} item(s)", function(n, context) {
        succeed()
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
    And the scenarios have these warnings:
      | scenario    | warning                                            |
      | Add an item | Cleanup of the scenario failed: The basket is gone |

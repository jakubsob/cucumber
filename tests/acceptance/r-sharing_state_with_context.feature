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
      | scenario    | warning                                             |
      | Add an item | Cleanup of the scenario failed: The basket is gone |

@rd
Feature: Failing steps
  A step fails when its step definition throws an error or a failed expectation.
  The steps after it are skipped, and the other scenarios still run.
  A step stops at its first failed expectation: unlike in a testthat test, the code after it doesn't run.
  An error is shown with its backtrace, the calls of the step down to where it was thrown, like in a testthat test.

  Background:
    Given a package

  Scenario: Steps after a failing step are skipped
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
          When I add an item
          Then the basket has 1 item
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {})
      when("I add an item", function(context) {
        expect_equal(1, 2)
      })
      then("the basket has {int} item", function(n, context) {
        stop("this step must not execute")
      })
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the steps have these results:
      | step                       | status  |
      | Given an empty basket      | passed  |
      | When I add an item         | failed  |
      | Then the basket has 1 item | skipped |

  Scenario: Undefined and ambiguous steps after a failing step keep their status
    Like in Cucumber, they're reported as undefined and ambiguous, so they're found in the same run.

    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          When I add an item
          Then the basket is checked
          And the basket is synced twice
      """
    And a file named "features/setup-steps.R" with
      """
      when("I add an item", function(context) stop("the basket is full"))
      then("the basket is synced {word}", function(word, context) {})
      then("the basket is synced {}", function(x, context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the steps have these results:
      | step                           | status    |
      | When I add an item             | failed    |
      | Then the basket is checked     | undefined |
      | And the basket is synced twice | ambiguous |

  Scenario: A step stops at its first failed expectation
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Then the basket has an apple
      """
    And a file named "features/setup-steps.R" with
      """
      then("the basket has an apple", function(context) {
        context$items <- c("pear", "plum")
        expect_equal(length(context$items), 1, label = "the number of items")
        expect_equal(context$items[[1]], "apple", label = "the first item")
      })
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the steps have these results:
      | step                         | status |
      | Then the basket has an apple | failed |
    And the errors are
      """
      [failure] Scenario: Add an item
      Step "the basket has an apple" failed
      i Feature: basket.feature
      i Scenario: Add an item
      i Step defined at: setup-steps.R:1
      Expected the number of items to equal 1.
      Differences:
      1/1 mismatches
      [1] 2 - 1 == 1
      """

  Scenario: A step that throws an error fails, and the other scenarios still run
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          When I add an item

        Scenario: Look into the basket
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {})
      when("I add an item", function(context) {
        stop("basket is full")
      })
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the errors are
      """
      [error] Scenario: Add an item
      Error: Step "I add an item" failed
      i Feature: basket.feature
      i Scenario: Add an item
      i Step defined at: setup-steps.R:2
      Caused by error:
      ! basket is full
      """
    And the scenarios have these results:
      | scenario             | status |
      | Add an item          | failed |
      | Look into the basket | passed |

  Scenario: An error is shown with the backtrace of the step
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      open_basket <- function() find_basket()
      find_basket <- function() stop("basket is missing")
      when("I add an item", function(context) {
        open_basket()
      })
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the output includes lines matching these patterns in order:
      """
      basket is missing
      Backtrace:
      open_basket\(\)
      find_basket\(\)
      """

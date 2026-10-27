@rd
Feature: Rerun reporter
  `CucumberRerunReporter` writes where the scenarios that didn't pass are, like Cucumber's `rerun`
  formatter, when the run ends. Each line is a feature file with the lines of its scenarios that didn't
  pass, like `basket.feature:5:14`. Passed to `features`, they run only those scenarios again.

  Background:
    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given a step that passes

        Scenario: Remove an item
          Given a step that fails

        Scenario Outline: Pay with <card>
          Given a step that <result>

          Examples:
            | card | result |
            | visa | passes |
            | amex | fails  |
      """
    And a file named "features/checkout.feature" with
      """
      Feature: Checkout
        Scenario: Ship
          Given a step that is pending
      """
    And a file named "features/setup-steps.R" with
      """
      given("a step that passes", function(context) {})
      given("a step that fails", function(context) stop("Failed"))
      given("a step that is pending", function(context) pending())
      """

  Scenario: Each feature file is a line with the scenarios that didn't pass
    When I run
      """
      test("features", reporter = CucumberRerunReporter$new("rerun.txt"), stop_on_failure = FALSE)
      """
    Then the file "rerun.txt" has these lines:
      """
      basket.feature:5:14
      checkout.feature:2
      """

  Scenario: The scenarios that didn't pass run again
    When I run
      """
      test("features", reporter = CucumberRerunReporter$new("rerun.txt"), stop_on_failure = FALSE)
      test("features", features = readLines("rerun.txt"), stop_on_failure = FALSE)
      """
    Then the scenarios have these results:
      | scenario       | status  |
      | Remove an item | failed  |
      | Pay with amex  | failed  |
      | Ship           | pending |

  Scenario: A scenario that passed when retried isn't in the file
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given a step that passes the second time

        Scenario: Remove an item
          Given a step that fails
      """
    And a file named "features/setup-flaky.R" with
      """
      attempts <- 0
      given("a step that passes the second time", function(context) {
        attempts <<- attempts + 1
        if (attempts < 2) stop("Not yet")
      })
      """
    When I run
      """
      test("features", reporter = CucumberRerunReporter$new("rerun.txt"), retry = 1, stop_on_failure = FALSE)
      """
    Then the file "rerun.txt" has these lines:
      """
      basket.feature:5
      checkout.feature:2
      """

  Scenario: The scenarios that fail_fast skipped are in the file
    When I run
      """
      test("features", reporter = CucumberRerunReporter$new("rerun.txt"), fail_fast = TRUE, stop_on_failure = FALSE)
      """
    Then the scenarios have these results:
      | scenario       | status  |
      | Add an item    | passed  |
      | Remove an item | failed  |
      | Pay with visa  | skipped |
      | Pay with amex  | skipped |
      | Ship           | skipped |
    And the file "rerun.txt" has these lines:
      """
      basket.feature:5:13:14
      checkout.feature:2
      """

  Scenario: Empty lines of a rerun file are ignored
    Like a rerun file edited by hand, with an empty line at its end.

    When I run
      """
      writeLines(c("basket.feature:5", "", " "), "rerun.txt")
      test("features", features = readLines("rerun.txt"), stop_on_failure = FALSE)
      """
    Then the scenarios have these results:
      | scenario       | status |
      | Remove an item | failed |

  Scenario: The file is empty when every scenario passed
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given a step that passes
      """
    And a file named "features/checkout.feature" with
      """
      Feature: Checkout
      """
    When I run
      """
      test("features", reporter = CucumberRerunReporter$new("rerun.txt"))
      """
    Then the file "rerun.txt" is empty

  Scenario: No scenario runs again when every scenario passed
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given a step that passes
      """
    And a file named "features/checkout.feature" with
      """
      Feature: Checkout
      """
    When I run
      """
      test("features", reporter = CucumberRerunReporter$new("rerun.txt"))
      test("features", features = readLines("rerun.txt"))
      """
    Then no scenario ran

Feature: Retry
  A scenario that fails, like one that depends on a slow service, can be run again with `retry`.
  It runs up to `retry` more times, until it passes, and its last attempt is its result.
  Only failed scenarios are retried: pending, undefined or ambiguous steps wouldn't pass on another attempt.

  Background:
    Given a package
    And a file named "features/setup-steps.R" with
      """
      attempts <- 0
      given("a step that passes the second time", function(context) {
        attempts <<- attempts + 1
        if (attempts < 2) stop("Not yet")
      })
      given("a step that always fails", function(context) {
        stop("Never")
      })
      given("a step that always passes", function(context) {})
      given("a pending step", function(context) {
        pending()
      })
      before(function(context, scenario) {
        cat("before", scenario$name, "\n")
      })
      """

  @rd
  Scenario: A failed scenario runs again until it passes
    Given a file named "features/flaky.feature" with
      """
      Feature: Flaky
        Scenario: Passes
          Given a step that always passes

        Scenario: Passes the second time
          Given a step that passes the second time

        Scenario: Always fails
          Given a step that always fails
      """
    When I run
      """
      test("features", retry = 2, stop_on_failure = FALSE)
      """
    Then the scenarios have these results:
      | scenario               | status | attempts |
      | Passes                 | passed | 1        |
      | Passes the second time | passed | 2        |
      | Always fails           | failed | 3        |

  Scenario: Each attempt runs the scenario's hooks, and after hooks get the attempt's result
    Given a file named "features/flaky.feature" with
      """
      Feature: Flaky
        Scenario: Passes the second time
          Given a step that passes the second time
      """
    And a file named "features/setup-after.R" with
      """
      after(function(context, scenario) {
        cat("after", scenario$status, "\n")
      })
      """
    When I run
      """
      test("features", retry = 1)
      """
    Then the output includes these lines in order:
      """
      before Passes the second time
      after failed
      before Passes the second time
      after passed
      """

  Scenario: Without retry a failed scenario runs once
    Given a file named "features/flaky.feature" with
      """
      Feature: Flaky
        Scenario: Passes the second time
          Given a step that passes the second time
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the scenarios have these results:
      | scenario               | status | attempts |
      | Passes the second time | failed | 1        |

  Scenario: Pending and undefined scenarios aren't retried
    Given a file named "features/unfinished.feature" with
      """
      Feature: Unfinished
        Scenario: Pending
          Given a pending step

        Scenario: Undefined
          Given a step that doesn't exist
      """
    When I run
      """
      test("features", retry = 2, stop_on_failure = FALSE)
      """
    Then the scenarios have these results:
      | scenario  | status    | attempts |
      | Pending   | pending   | 1        |
      | Undefined | undefined | 1        |

  Scenario: testthat gets the expectations and warnings of only the last attempt
    Given a file named "features/setup-warnings.R" with
      """
      tries <- 0
      given("a step that warns and passes the second time", function(context) {
        tries <<- tries + 1
        expect_true(TRUE)
        warning("Attempt ", tries)
        if (tries < 2) stop("Not yet")
      })
      """
    And a file named "features/flaky.feature" with
      """
      Feature: Flaky
        Scenario: Passes the second time
          Given a step that warns and passes the second time
      """
    When I run
      """
      test("features", retry = 1)
      """
    Then testthat counts these results of the scenarios:
      | scenario               | passed | warnings |
      | Passes the second time | 1      | 1        |
    And the scenarios have these warnings:
      | scenario               | warning   |
      | Passes the second time | Attempt 2 |

  @rd
  Scenario: The summary counts only the last attempt of a scenario
    Given a file named "features/flaky.feature" with
      """
      Feature: Flaky
        Scenario: Passes the second time
          Given a step that passes the second time
      """
    When I run
      """
      test("features", retry = 1, reporter = CucumberSummaryReporter$new())
      """
    Then the output includes "1 scenario (1 passed)"
    And the output includes "1 step (1 passed)"

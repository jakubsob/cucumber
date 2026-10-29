@rd
Feature: Reporters
  Every reporter gets the run as Cucumber Messages. `CucumberMultiReporter` sends them to
  several reporters, to show the progress of a run and write its reports at once.
  A reporter's `$report()` method sends it the messages stored in an ndjson file, like the one a
  `CucumberMessagesReporter` writes, to report a run after it ran.
  A reporter that prints, like `CucumberSummaryReporter`, prints to a `file` instead of the console
  when it's given one, replaced by each run.

  Background:
    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
          When I add an item

        Scenario: Remove an item
          Given an empty basket
          When I remove an item
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) context$items <- 0)
      when("I add an item", function(context) context$items <- context$items + 1)
      when("I remove an item", function(context) stop("The basket is empty"))
      """

  Scenario: A run shows its progress and writes its reports
    The run's messages aren't stored, only the reports written from them.

    When I run it and it fails
      """
      test("features", reporter = CucumberMultiReporter$new(list(
        CucumberProgressReporter$new(),
        CucumberHtmlReporter$new("report.html"),
        CucumberJunitReporter$new("report.xml")
      )))
      """
    Then the output includes
      """
      2 scenarios (1 failed, 1 passed)
      4 steps (1 failed, 3 passed)
      """
    And the HTML report "report.html" shows these steps:
      | step                  | status |
      | Given an empty basket | passed |
      | When I add an item    | passed |
      | Given an empty basket | passed |
      | When I remove an item | failed |
    And the JUnit report "report.xml" has these test cases:
      | name           | result  |
      | Add an item    | passed  |
      | Remove an item | failure |
    And there is no file "cucumber.ndjson"

  Scenario: The reports of a stored run are written after the run
    When I run
      """
      test("features", reporter = CucumberMessagesReporter$new("cucumber.ndjson"), stop_on_failure = FALSE)
      CucumberHtmlReporter$new("report.html")$report("cucumber.ndjson")
      CucumberJunitReporter$new("report.xml")$report("cucumber.ndjson")
      """
    Then the HTML report "report.html" shows these steps:
      | step                  | status |
      | Given an empty basket | passed |
      | When I add an item    | passed |
      | Given an empty basket | passed |
      | When I remove an item | failed |
    And the JUnit report "report.xml" has these test cases:
      | name           | result  |
      | Add an item    | passed  |
      | Remove an item | failure |

  Scenario: A stored run is printed again
    When I run
      """
      test("features", reporter = CucumberMessagesReporter$new("cucumber.ndjson"), stop_on_failure = FALSE)
      CucumberProgressReporter$new()$report("cucumber.ndjson")
      """
    Then the output includes
      """
      2 scenarios (1 failed, 1 passed)
      4 steps (1 failed, 3 passed)
      """

  Scenario Outline: A report is written into directories that don't exist yet
    When I run
      """
      test("features", reporter = <reporter>$new("test-results/<file>"), stop_on_failure = FALSE)
      """
    Then there is a file "test-results/<file>"

    Examples:
      | reporter                 | file            |
      | CucumberMessagesReporter | cucumber.ndjson |
      | CucumberHtmlReporter     | report.html     |
      | CucumberJunitReporter    | junit.xml       |
      | CucumberRerunReporter    | rerun.txt       |

  Scenario Outline: <reporter> prints to a file
    When I run
      """
      test("features", reporter = <reporter>$new(file = "test-results/output.txt"), stop_on_failure = FALSE)
      """
    Then the file "test-results/output.txt" includes "<text>" 1 time
    And the output doesn't include "<text>"

    Examples:
      | reporter                    | text                             |
      | CucumberSummaryReporter     | 2 scenarios (1 failed, 1 passed) |
      | CucumberDotsReporter        | 2 scenarios (1 failed, 1 passed) |
      | CucumberProgressReporter    | 2 scenarios (1 failed, 1 passed) |
      | CucumberProgressBarReporter | 2 scenarios (1 failed, 1 passed) |
      | CucumberPrettyReporter      | Scenario: Add an item            |
      | CucumberUsageReporter       | Step definition / Step           |

  Scenario: Each run replaces the file a reporter prints to
    When I run
      """
      test("features", reporter = CucumberSummaryReporter$new(file = "summary.txt"), stop_on_failure = FALSE)
      test("features", reporter = CucumberSummaryReporter$new(file = "summary.txt"), stop_on_failure = FALSE)
      """
    Then the file "summary.txt" includes "2 scenarios (1 failed, 1 passed)" 1 time

  Scenario: A stored run is printed to a file
    When I run
      """
      test("features", reporter = CucumberMessagesReporter$new("cucumber.ndjson"), stop_on_failure = FALSE)
      CucumberSummaryReporter$new(file = "summary.txt")$report("cucumber.ndjson")
      """
    Then the file "summary.txt" includes "2 scenarios (1 failed, 1 passed)" 1 time
    And the output doesn't include "2 scenarios"

  Scenario: A report that can't be written fails the run
    The scenarios run, and the error names the reporter that failed when the run ended.

    When I run it and it fails
      """
      test("features", reporter = CucumberMultiReporter$new(list(
        CucumberProgressReporter$new(),
        CucumberHtmlReporter$new("features")
      )), stop_on_failure = FALSE)
      """
    Then it fails with
      """
      Error:
      ! Reporter `CucumberHtmlReporter` failed in `end_run()`.
      Caused by error:
      ! cannot open the connection
      """
    And the output includes "2 scenarios (1 failed, 1 passed)"

  Scenario: Only cucumber's reporters can be combined
    When I run it and it fails
      """
      CucumberMultiReporter$new(list(CucumberProgressReporter$new(), testthat::ProgressReporter$new()))
      """
    Then it fails with
      """
      Error:
      ! `reporters[[2]]` must be a `CucumberReporter`, or `NULL` to report nothing.
      i testthat reporters can't report a cucumber run, use one of cucumber's, like `CucumberProgressReporter$new()`.
      """

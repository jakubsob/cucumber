@rd
Feature: Reporters
  Every reporter gets the run as Cucumber Messages. `CucumberMultiReporter` sends them to
  several reporters, to show the progress of a run and write its reports at once.
  `report()` sends a reporter the messages stored in an ndjson file, like the one a
  `CucumberMessagesReporter` writes, to report a run after it ran.

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
    Then the output includes "1 failed"
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
    Then the output includes "1 failed"

  Scenario: A report that can't be written fails the run
    The scenarios run, and the error names the reporter that failed when the run ended.

    When I run it and it fails
      """
      test("features", reporter = CucumberMultiReporter$new(list(
        CucumberProgressReporter$new(),
        CucumberHtmlReporter$new("missing/report.html")
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

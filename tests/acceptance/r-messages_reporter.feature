@rd
Feature: Messages reporter
  `CucumberMessagesReporter` writes a run as Cucumber Messages, one JSON message per line (NDJSON),
  like the `message` formatter of other Cucumber implementations. Official tools read it,
  like the HTML, JUnit and JSON formatters.

  Background:
    Given a package
    And a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
          When I add 2 apples
          Then the basket has 2 items
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) context$items <- 0)
      given("an empty basket", function(context) {})
      when("I add {int} apples", function(int, context) context$items <- context$items + int)
      then("the basket has {int} items", function(int, context) expect_equal(context$items, int))
      """

  Scenario: The run is written as messages
    When I run
      """
      test("features", reporter = CucumberMessagesReporter$new("messages.ndjson"))
      messages <- lapply(readLines("messages.ndjson"), jsonlite::fromJSON)
      cat(vapply(messages, names, character(1)), sep = "\n")
      """
    Then the output includes
      """
      meta
      source
      gherkinDocument
      pickle
      hook
      stepDefinition
      stepDefinition
      stepDefinition
      testRunStarted
      testCase
      testCaseStarted
      testStepStarted
      testStepFinished
      testStepStarted
      testStepFinished
      testStepStarted
      testStepFinished
      testStepStarted
      testStepFinished
      testCaseFinished
      testRunFinished
      """

  Scenario: The messages are written to a connection
    When I run
      """
      test("features", reporter = CucumberMessagesReporter$new(stdout()))
      """
    Then the output includes
      """
      {"testRunFinished":
      """

  Scenario: Each step's result is written as a testStepFinished message
    Given a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {})
      when("I add {int} apples", function(int, context) pending())
      """
    When I run
      """
      test("features", reporter = CucumberMessagesReporter$new("messages.ndjson"), stop_on_failure = FALSE)
      messages <- lapply(readLines("messages.ndjson"), jsonlite::fromJSON)
      finished <- Filter(\(message) !is.null(message$testStepFinished), messages)
      cat(vapply(finished, \(message) message$testStepFinished$testStepResult$status, character(1)), sep = "\n")
      """
    Then the output includes
      """
      PASSED
      PENDING
      UNDEFINED
      """

  Scenario: The run is written as messages and its progress is printed
    When I run
      """
      test("features", reporter = CucumberMultiReporter$new(list(
        CucumberPrettyReporter$new(),
        CucumberMessagesReporter$new("messages.ndjson")
      )))
      cat(nrow(read_messages("messages.ndjson")$scenarios), "scenario written\n")
      """
    Then the output includes
      """
      Scenario: Add an item
      v Given an empty basket
      v When I add 2 apples
      v Then the basket has 2 items
      """
    And the output includes "1 scenario written"

  Scenario: A failed step's error has the backtrace of the step as its stack trace
    Given a file named "features/setup-steps.R" with
      """
      open_basket <- function() find_basket()
      find_basket <- function() stop("basket is missing")
      given("an empty basket", function(context) open_basket())
      """
    When I run
      """
      test("features", reporter = CucumberMessagesReporter$new("messages.ndjson"), stop_on_failure = FALSE)
      messages <- lapply(readLines("messages.ndjson"), jsonlite::fromJSON)
      finished <- Filter(\(message) !is.null(message$testStepFinished$testStepResult$exception), messages)
      cat(finished[[1]]$testStepFinished$testStepResult$exception$stackTrace)
      """
    Then the output includes lines matching these patterns in order:
      """
      open_basket\(\)
      find_basket\(\)
      """

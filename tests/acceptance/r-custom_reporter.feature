@rd
Feature: Custom reporter
  Extend `CucumberReporter` to report the run your way. A reporter gets the start and the end of the
  run, each of its Cucumber Messages and the warnings raised in it.
  Pass the reporter to `test()` or `run()` with `reporter`. Only cucumber reporters can report a run,
  testthat reporters can't.

  Background:
    Given a package
    And a file named "event-reporter.R" with
      """
      EventReporter <- R6::R6Class(
        "EventReporter",
        inherit = cucumber::CucumberReporter,
        public = list(
          start_run = function() cat("start run\n"),
          end_run = function(error) {
            cat("end run:", if (is.null(error)) "passed" else conditionMessage(error), "\n")
          },
          add_message = function(envelope) cat("message:", names(envelope), "\n"),
          add_warning = function(warning) cat("warning:", conditionMessage(warning), "\n")
        )
      )
      """

  Scenario: A reporter gets the run as Cucumber Messages
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {})
      """
    When I run
      """
      source("event-reporter.R")
      test("features", reporter = EventReporter$new())
      """
    Then the output includes
      """
      start run
      message: meta
      message: source
      message: gherkinDocument
      message: pickle
      message: stepDefinition
      message: testRunStarted
      message: testCase
      message: testCaseStarted
      message: testStepStarted
      message: testStepFinished
      message: testCaseFinished
      message: testRunFinished
      end run: passed
      """

  Scenario: A reporter gets the warnings raised in steps and hooks
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) warning("the database is slow"))
      given("an empty basket", function(context) warning("the basket is dusty"))
      """
    When I run
      """
      source("event-reporter.R")
      test("features", reporter = EventReporter$new())
      """
    Then the output includes
      """
      message: testCaseStarted
      message: testStepStarted
      warning: the database is slow
      message: testStepFinished
      message: testStepStarted
      warning: the basket is dusty
      message: testStepFinished
      message: testCaseFinished
      """

  Scenario: A reporter gets the error that stopped the run
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before_all(function() stop("the server didn't start"))
      given("an empty basket", function(context) {})
      """
    When I run
      """
      source("event-reporter.R")
      test("features", reporter = EventReporter$new(), stop_on_failure = FALSE)
      """
    Then the output includes these lines in order:
      """
      start run
      end run: the server didn't start
      """

  Scenario: A reporter that fails stops the run with its error
    The scenarios after it don't run, and the error names the reporter and the event it failed in.

    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket

        Scenario: Remove an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {})
      """
    And a file named "broken-reporter.R" with
      """
      BrokenReporter <- R6::R6Class(
        "BrokenReporter",
        inherit = EventReporter,
        public = list(
          add_message = function(envelope) {
            if (!is.null(envelope$testStepFinished)) stop("can't format the step")
            super$add_message(envelope)
          }
        )
      )
      """
    When I run it and it fails
      """
      source("event-reporter.R")
      source("broken-reporter.R")
      test("features", reporter = BrokenReporter$new(), stop_on_failure = FALSE)
      """
    Then it fails with
      """
      Error:
      ! Reporter `BrokenReporter` failed in `add_message()`.
      Caused by error:
      ! can't format the step
      """
    And the output includes "message: testCaseStarted" once

  Scenario: A testthat reporter can't report a run
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {})
      """
    When I run it and it fails
      """
      test("features", reporter = testthat::ProgressReporter$new())
      """
    Then it fails with
      """
      Error in `lapply()`:
      ! `reporter` must be a `CucumberReporter`, or `NULL` to report nothing.
      i testthat reporters can't report a cucumber run, use one of cucumber's, like `CucumberProgressReporter$new()`.
      """

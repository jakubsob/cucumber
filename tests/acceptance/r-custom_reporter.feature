Feature: Custom reporter
  Extend `CucumberReporter` to report the run, features, scenarios, steps, hooks and warnings your way.
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
          start_scenario = function(scenario_name) cat("start scenario:", scenario_name, "\n"),
          add_warning = function(warning) cat("warning:", conditionMessage(warning), "\n"),
          start_feature = function(feature_name) {
            super$start_feature(feature_name)
            cat("start feature:", feature_name, "\n")
          },
          end_feature = function() {
            super$end_feature()
            cat("end feature\n")
          },
          start_step = function(step) {
            cat("start step:", step$keyword, step$text, "\n")
          },
          end_step = function(step) {
            cat("end step:", step$keyword, step$type, step$text, step$status, "\n")
          },
          end_hook = function(status, error) {
            cat("end hook:", status, conditionMessage(error), "\n")
          },
          end_scenario = function(status) {
            cat("end scenario:", status, "\n")
          }
        )
      )
      """

  Scenario: A reporter gets each feature, step and scenario
    A step keeps the keyword it's written with. Its type is what the keyword means: `And` and `But` take the type of the step before, `*` is Unknown.

    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
          And a cucumber
          When I add the cucumber
          Then the basket has 1 item
          But the basket isn't full
          * the basket is light
      """
    And a file named "features/setup-steps.R" with
      """
      given("an empty basket", function(context) {})
      given("a cucumber", function(context) {})
      when("I add the cucumber", function(context) {})
      then("the basket has {int} item", function(n, context) {})
      then("the basket isn't full", function(context) {})
      then("the basket is light", function(context) {})
      """
    When I run
      """
      source("event-reporter.R")
      test("features", reporter = EventReporter$new())
      """
    Then the output includes
      """
      start run
      start feature: Feature: Basket
      start scenario: Scenario: Add an item
      start step: Given an empty basket
      end step: Given Context an empty basket passed
      start step: And a cucumber
      end step: And Context a cucumber passed
      start step: When I add the cucumber
      end step: When Action I add the cucumber passed
      start step: Then the basket has 1 item
      end step: Then Outcome the basket has 1 item passed
      start step: But the basket isn't full
      end step: But Outcome the basket isn't full passed
      start step: * the basket is light
      end step: * Unknown the basket is light passed
      end scenario: passed
      end feature
      end run: passed
      """

  Scenario: A reporter gets the hooks that failed or are pending
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      after(function(context, scenario) stop("can't close the database"))
      before(function(context, scenario) pending("no database yet"))
      given("an empty basket", function(context) {})
      """
    When I run
      """
      source("event-reporter.R")
      test("features", reporter = EventReporter$new(), stop_on_failure = FALSE)
      """
    Then the output includes
      """
      start feature: Feature: Basket
      start scenario: Scenario: Add an item
      end hook: pending Hook is pending: no database yet
      start step: Given an empty basket
      end step: Given Context an empty basket skipped
      end hook: failed can't close the database
      end scenario: failed
      end feature
      """

  Scenario: A reporter gets the hooks that skipped the scenario
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Sync the basket
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) skip_scenario("the API is down"))
      given("an empty basket", function(context) {})
      """
    When I run
      """
      source("event-reporter.R")
      test("features", reporter = EventReporter$new())
      """
    Then the output includes
      """
      end hook: skipped Reason: the API is down
      start step: Given an empty basket
      end step: Given Context an empty basket skipped
      end scenario: skipped
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
      start scenario: Scenario: Add an item
      warning: the database is slow
      start step: Given an empty basket
      warning: the basket is dusty
      end step: Given Context an empty basket passed
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
    Then the output includes
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
          end_step = function(step) stop("can't format the step")
        )
      )
      """
    When I run it and it fails
      """
      source("event-reporter.R")
      source("broken-reporter.R")
      test("features", reporter = BrokenReporter$new(), stop_on_failure = FALSE)
      """
    Then it fails with "Reporter `BrokenReporter` failed in `end_step()`."
    And it fails with "can't format the step"
    And the output includes "start scenario: Scenario: Add an item"
    And the output doesn't include "Remove an item"

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
    Then it fails with "`reporter` must be a `CucumberReporter`, or `NULL` to report nothing."

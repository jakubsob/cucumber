Feature: Custom reporter
  Extend `CucumberReporter` to report features, steps, hooks and scenarios your way.
  Pass the reporter to `test()` or `run()` with `reporter`.

  Background:
    Given a package
    And a file named "event-reporter.R" with
      """
      EventReporter <- R6::R6Class(
        "EventReporter",
        inherit = cucumber::CucumberReporter,
        public = list(
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
      start feature: Feature: Basket
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
      end hook: pending Hook is pending: no database yet
      start step: Given an empty basket
      end step: Given Context an empty basket skipped
      end hook: failed can't close the database
      end scenario: failed
      end feature
      """

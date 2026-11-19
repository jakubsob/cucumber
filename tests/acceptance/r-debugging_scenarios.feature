Feature: Debugging scenarios
  To find out why a scenario fails, run only that scenario with `debug = TRUE`, like
  `test(features = "basket.feature:3", debug = TRUE)`. Select it with `name` or a line of `features`,
  or the debugger opens in every scenario.

  The debugger opens at the first line of every step definition and hook that runs, like `debugonce()` on each
  of them just before it's called. Step definitions and hooks are anonymous functions, so just before it opens
  cucumber says which step or hook it is, where in the feature file it runs and where it's defined. There, look into the step's parameters and `context`, and step with the
  debugger's commands: `n` runs the next line, `s` steps into a call, `c` continues and `Q` stops.
  When you step past the last line of a step or a hook, the debugger opens at the first line of the next one,
  in the order the scenario runs them: its `before()` hooks, then for each step its `before_step()` hooks,
  the step definition and its `after_step()` hooks, and last its `after()` hooks.
  `before_all()` and `after_all()` hooks run for the whole run, not for a scenario, so they don't stop.
  The `cucumber.debug_hint` option sets that hint with a function of `what` and `bullets` that returns
  the lines to print, or `NULL` for none.

  The debugger needs an interactive session. There is no one to step in a test run, so the scenarios below replace
  it by a line that names where it would open, like the location of `debug at ./setup-steps.R#4: {`.

  Background:
    Given a package
    And the debugger is replaced by one that names where it opens
    And a file named "features/basket.feature" with
      """
      Feature: Basket

        Scenario: Eat some cucumbers
          Given I have 5 cucumbers
          When I eat 2 cucumbers
          Then I have 4 cucumbers left

        Scenario: Eat none
          Given I have 5 cucumbers
          Then I have 5 cucumbers left
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) {
        context$cucumbers <- 0
      })
      given("I have {int} cucumbers", function(n_cucumbers, context) {
        context$cucumbers <- n_cucumbers
      })
      when("I eat {int} cucumber(s)", function(n_eaten, context) {
        context$cucumbers <- context$cucumbers - n_eaten
      })
      then("I have {int} cucumbers left", function(n_left, context) {
        expect_equal(context$cucumbers, n_left)
      })
      """

  @rd
  Scenario: Debug a scenario that fails
    When I run it and it fails
      """
      test("features", name = "Eat some cucumbers", debug = TRUE)
      """
    Then the scenarios have these results:
      | scenario           | status |
      | Eat some cucumbers | failed |
    And the output includes these lines in order:
      """
      Debugging Hook `before()`
      i Feature: basket.feature:3
      i Scenario: Eat some cucumbers
      i Hook defined at: setup-steps.R:1
      Debugger opens in function(context, scenario) at setup-steps.R:1
      Debugging step "I have 5 cucumbers"
      i Feature: basket.feature:4
      i Scenario: Eat some cucumbers
      i Step defined at: setup-steps.R:4
      Debugger opens in function(n_cucumbers, context) at setup-steps.R:4
      Debugging step "I eat 2 cucumbers"
      i Feature: basket.feature:5
      i Scenario: Eat some cucumbers
      i Step defined at: setup-steps.R:7
      Debugger opens in function(n_eaten, context) at setup-steps.R:7
      Debugging step "I have 4 cucumbers left"
      i Feature: basket.feature:6
      i Scenario: Eat some cucumbers
      i Step defined at: setup-steps.R:10
      Debugger opens in function(n_left, context) at setup-steps.R:10
      """
    And the output doesn't include "Eat none"

  Scenario: Debug the scenario at a line of its feature file
    When I run
      """
      test("features", features = "basket.feature:8", debug = TRUE)
      """
    Then the output includes these lines in order:
      """
      Debugger opens in function(context, scenario) at setup-steps.R:1
      Debugger opens in function(n_cucumbers, context) at setup-steps.R:4
      Debugger opens in function(n_left, context) at setup-steps.R:10
      """

  Scenario: A step that runs again opens the debugger again
    Given a file named "features/basket.feature" with
      """
      Feature: Basket

        Scenario: Eat twice
          Given I have 5 cucumbers
          When I eat 2 cucumbers
          And I eat 1 cucumber
      """
    When I run
      """
      test("features", debug = TRUE)
      """
    Then the output includes these lines in order:
      """
      Debugger opens in function(n_cucumbers, context) at setup-steps.R:4
      Debugger opens in function(n_eaten, context) at setup-steps.R:7
      Debugger opens in function(n_eaten, context) at setup-steps.R:7
      """

  Scenario: Hooks around the steps and the scenario open the debugger too
    Given a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) {
        context$cucumbers <- 0
      })
      before_step(function(context, step) {
        context$step <- step$text
      })
      given("I have {int} cucumbers", function(n_cucumbers, context) {
        context$cucumbers <- n_cucumbers
      })
      then("I have {int} cucumbers left", function(n_left, context) {
        expect_equal(context$cucumbers, n_left)
      })
      after_step(function(context, step) {
        context$step <- NULL
      })
      after(function(context, scenario) {
        context$cucumbers <- NULL
      })
      before_all(function() {
        options(cucumber_example = TRUE)
      })
      """
    When I run
      """
      test("features", name = "Eat none", debug = TRUE)
      """
    Then the output includes these lines in order:
      """
      Debugger opens in function(context, scenario) at setup-steps.R:1
      Debugger opens in function(context, step) at setup-steps.R:4
      Debugger opens in function(n_cucumbers, context) at setup-steps.R:7
      Debugger opens in function(context, step) at setup-steps.R:13
      Debugger opens in function(context, step) at setup-steps.R:4
      Debugger opens in function(n_left, context) at setup-steps.R:10
      Debugger opens in function(context, step) at setup-steps.R:13
      Debugger opens in function(context, scenario) at setup-steps.R:16
      """
    And the output doesn't include "setup-steps.R:19"

  Scenario: The debugger doesn't open without debug
    When I run
      """
      test("features", name = "Eat none")
      """
    Then the output doesn't include "Debugger opens in"

  Scenario: Write your own hint
    Set the `cucumber.debug_hint` option to a function of `what`, like `step "I have 5 cucumbers"`, and
    `bullets`, the lines of where it is. It returns the lines to print. This one keeps only where it's defined.

    When I run
      """
      my_hint <- function(what, bullets) {
        c(paste("==>", what), bullets[grepl("defined at", bullets)])
      }
      withr::with_options(
        list(cucumber.debug_hint = my_hint),
        test("features", name = "Eat none", debug = TRUE)
      )
      """
    Then the output includes these lines in order:
      """
      ==> Hook `before()`
      Hook defined at: setup-steps.R:1
      Debugger opens in function(context, scenario) at setup-steps.R:1
      ==> step "I have 5 cucumbers"
      Step defined at: setup-steps.R:4
      Debugger opens in function(n_cucumbers, context) at setup-steps.R:4
      ==> step "I have 5 cucumbers left"
      Step defined at: setup-steps.R:10
      Debugger opens in function(n_left, context) at setup-steps.R:10
      """
    And the output doesn't include "Debugging"

  Scenario: Disable the hint
    A hint that returns `NULL` prints nothing before the debugger opens.

    When I run
      """
      withr::with_options(
        list(cucumber.debug_hint = function(what, bullets) NULL),
        test("features", name = "Eat none", debug = TRUE)
      )
      """
    Then the output includes these lines in order:
      """
      Debugger opens in function(context, scenario) at setup-steps.R:1
      Debugger opens in function(n_cucumbers, context) at setup-steps.R:4
      Debugger opens in function(n_left, context) at setup-steps.R:10
      """
    And the output doesn't include "Debugging"
    And the output doesn't include "defined at"

  Scenario: cucumber.debug_hint must be a function
    When I run it and it fails
      """
      withr::with_options(list(cucumber.debug_hint = "no"), test("features", debug = TRUE))
      """
    Then it fails with
      """
      Error:
      ! The `cucumber.debug_hint` option must be a function of `what` and `bullets`.
      """

  Scenario: debug must be TRUE or FALSE
    When I run it and it fails
      """
      test("features", debug = "yes")
      """
    Then it fails with
      """
      Error:
      ! `debug` must be `TRUE` or `FALSE`.
      """

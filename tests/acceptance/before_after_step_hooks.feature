Feature: Step hooks
  `before_step()` and `after_step()` run code before and after each step.
  They get the step, and after step hooks also get its result.
  They don't run for skipped, undefined or ambiguous steps. A failing step hook fails the step.

  Background:
    Given a package

  @rd
  Scenario: Step hooks run around each step and after step hooks get its result
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
      before_step(function(context, step) cat("before:", step$keyword, step$text, "\n"))
      after_step(function(context, step) cat("after:", step$text, step$status, "\n"))
      given("an empty basket", function(context) {})
      when("I add an item", function(context) stop("basket is full"))
      then("the basket has {int} item", function(n, context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the output includes
      """
      before: Given an empty basket
      after: an empty basket passed
      before: When I add an item
      after: I add an item failed
      """
    And the steps have these results:
      | step                       | status  |
      | Given an empty basket      | passed  |
      | When I add an item         | failed  |
      | Then the basket has 1 item | skipped |
    And the output doesn't include "before: Then the basket has 1 item"
    And the output doesn't include "after: the basket has 1 item"

  @rd
  Scenario: Step hooks get where the step is, and its Data Table and Doc String
    They get the Data Table and the Doc String as the step definition gets them.

    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add items
          Given an empty basket
          When I add these items
            | item   |
            | apple  |
            | banana |
          And I add a note
            ```
            A gift
            ```
      """
    And a file named "features/setup-steps.R" with
      """
      before_step(function(context, step) {
        cat(step$text, "at line", step$line, "\n")
        if (!is.null(step$data_table)) cat("items:", step$data_table$item, "\n")
        if (!is.null(step$doc_string)) cat("note:", step$doc_string, "\n")
      })
      given("an empty basket", function(context) {})
      when("I add these items", function(table, context) {})
      when("I add a note", function(note, context) {})
      """
    When I run
      """
      test("features")
      """
    Then the output includes these lines in order:
      """
      an empty basket at line 3
      I add these items at line 4
      items: apple banana
      I add a note at line 8
      note: A gift
      """

  Scenario: An after step hook gets the error of a failed step
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      after_step(function(context, step) {
        if (is.null(step$error)) cat("no error:", step$text, "\n") else cat("error:", conditionMessage(step$error), "\n")
      })
      given("an empty basket", function(context) {})
      when("I add an item", function(context) stop("basket is full"))
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the output includes these lines in order:
      """
      no error: an empty basket
      error: Step "I add an item" failed
      ! basket is full
      """

  Scenario: A failing step hook fails the step
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      after_step(function(context, step) stop("step left a mess"))
      given("an empty basket", function(context) {})
      when("I add an item", function(context) stop("this step must not execute"))
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the errors are
      """
      [error] Scenario: Add an item
      Error: Hook `after_step()` failed
      i Feature: basket.feature
      i Scenario: Add an item
      i Hook defined at: setup-steps.R:1
      Caused by error:
      ! step left a mess
      """
    And the steps have these results:
      | step                  | status  |
      | Given an empty basket | failed  |
      | When I add an item    | skipped |

  Scenario: A failing before step hook fails the step without running it
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before_step(function(context, step) stop("no basket"))
      given("an empty basket", function(context) cat("the step ran\n"))
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the steps have these results:
      | step                  | status |
      | Given an empty basket | failed |
    And the output doesn't include "the step ran"

  Scenario: A step hook can't skip the scenario
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      before_step(function(context, step) skip_scenario("The shop is closed"))
      when("I add an item", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the steps have these results:
      | step               | status |
      | When I add an item | failed |
    And the errors are
      """
      [error] Scenario: Add an item
      Error: Hook `before_step()` failed
      i Feature: basket.feature
      i Scenario: Add an item
      i Hook defined at: setup-steps.R:1
      Caused by error:
      ! `skip_scenario()` can only be called in a `before_all()`, `before()` or `after()` hook or a step.
      """

  Scenario: A failing after step hook fails a pending step
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      after_step(function(context, step) stop("step left a mess"))
      given("an empty basket", function(context) pending())
      """
    When I run
      """
      test("features", strict = FALSE, stop_on_failure = FALSE)
      """
    Then the errors are
      """
      [error] Scenario: Add an item
      Error: Hook `after_step()` failed
      i Feature: basket.feature
      i Scenario: Add an item
      i Hook defined at: setup-steps.R:1
      Caused by error:
      ! step left a mess
      """
    And the steps have these results:
      | step                  | status |
      | Given an empty basket | failed |

  Scenario: Step hooks don't run for undefined and ambiguous steps
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Undefined
          Given a step nobody defined
        Scenario: Ambiguous
          Given I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      before_step(function(context, step) cat("before:", step$text, "\n"))
      after_step(function(context, step) cat("after:", step$text, "\n"))
      given("I add an item", function(context) {})
      given("I add an {word}", function(thing, context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the steps have these results:
      | step                        | status    |
      | Given a step nobody defined | undefined |
      | Given I add an item         | ambiguous |
    And the output doesn't include "before:"
    And the output doesn't include "after:"

  Scenario: Step hooks share the scenario's context with its steps and hooks
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) context$log <- "before")
      before_step(function(context, step) context$log <- c(context$log, "before step"))
      after_step(function(context, step) context$log <- c(context$log, "after step"))
      after(function(context, scenario) cat(context$log, sep = "\n"))
      given("an empty basket", function(context) context$log <- c(context$log, "step"))
      """
    When I run
      """
      test("features")
      """
    Then the output includes these lines in order:
      """
      before
      before step
      step
      after step
      """

  Scenario: Before step hooks run in definition order and after step hooks in reverse order
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before_step(function(context, step) cat("before step 1\n"))
      before_step(function(context, step) cat("before step 2\n"))
      after_step(function(context, step) cat("after step 1\n"))
      after_step(function(context, step) cat("after step 2\n"))
      given("an empty basket", function(context) cat("step\n"))
      """
    When I run
      """
      test("features")
      """
    Then the output includes these lines in order:
      """
      before step 1
      before step 2
      step
      after step 2
      after step 1
      """

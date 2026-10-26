Feature: Hooks
  `before()` and `after()` run code before and after each scenario, like opening and closing a connection.
  Define as many as you need: before hooks run in the order they are defined,
  after hooks in the reverse order. Hooks of several files are defined in the order the files are loaded:
  the `helper-*.R` files, then the `setup-*.R` files, each in alphabetical order.
  Where a hook is defined has no impact on what scenarios it runs for.
  Give a hook a `name` to find it in error messages.
  A failing before hook skips the scenario's steps and fails it. After hooks run even when the scenario failed,
  and a failing after hook fails it.

  What a before hook does is invisible to people who only read the features. For setup they should read,
  use a Background instead, and keep before hooks for low-level work like starting a browser or emptying a database.

  Background:
    Given a package

  @rd
  Scenario: Before hooks run in definition order and after hooks in reverse order
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) cat("before 1\n"))
      before(function(context, scenario) cat("before 2\n"))
      after(function(context, scenario) cat("after 1\n"))
      after(function(context, scenario) cat("after 2\n"))
      given("an empty basket", function(context) cat("step\n"))
      """
    When I run
      """
      test("features")
      """
    Then it passes
    And the output includes
      """
      before 1
      before 2
      step
      after 2
      after 1
      """

  Scenario: Hooks of several files run in the order the files are loaded
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-b.R" with
      """
      before(function(context, scenario) cat("before setup-b\n"))
      after(function(context, scenario) cat("after setup-b\n"))
      """
    And a file named "features/setup-a.R" with
      """
      before(function(context, scenario) cat("before setup-a\n"))
      after(function(context, scenario) cat("after setup-a\n"))
      given("an empty basket", function(context) {})
      """
    And a file named "features/helper-z.R" with
      """
      before(function(context, scenario) cat("before helper-z\n"))
      after(function(context, scenario) cat("after helper-z\n"))
      """
    When I run
      """
      test("features")
      """
    Then the output includes these lines in order:
      """
      before helper-z
      before setup-a
      before setup-b
      after setup-b
      after setup-a
      after helper-z
      """

  @rd
  Scenario: Hooks get the scenario, and after hooks get its result
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        @smoke
        Scenario: Add an item
          Given an empty basket
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) {
        cat("before:", scenario$name, scenario$tags, basename(scenario$uri), "\n")
      })
      after(function(context, scenario) {
        cat("after:", scenario$status, conditionMessage(scenario$error), "\n")
      })
      given("an empty basket", function(context) {})
      when("I add an item", function(context) stop("basket is full"))
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the output includes
      """
      before: Add an item @smoke basket.feature
      """
    And the output includes
      """
      after: failed Step "I add an item" failed
      """

  @rd
  Scenario: Hooks get where the scenario is and its id
    The line of an example of a Scenario Outline is the line of its row.
    Each scenario has an id of its own.

    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Empty basket
          Given an empty basket

        Scenario Outline: Add <n> items
          Given an empty basket

          Examples:
            | n |
            | 1 |
            | 2 |
      """
    And a file named "features/setup-steps.R" with
      """
      ids <- character()
      before(function(context, scenario) {
        ids <<- c(ids, scenario$id)
        cat(scenario$name, "at", paste0(basename(scenario$uri), ":", scenario$line), "\n")
      })
      after_all(function() cat(length(unique(ids)), "ids", "\n"))
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features")
      """
    Then the output includes these lines in order:
      """
      Empty basket at basket.feature:2
      Add 1 items at basket.feature:10
      Add 2 items at basket.feature:11
      3 ids
      """

  @rd
  Scenario: A named hook's errors start with its name
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Save the basket
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) stop("connection refused"), name = "Connect to the database")
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the steps and hooks have these results:
      | step                           | status  |
      | Before Connect to the database | failed  |
      | Given an empty basket          | skipped |
    And the error message includes "Hook \"Connect to the database\" failed: connection refused"

  @rd
  Scenario: A failing before hook skips the steps and fails the scenario
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) {
        stop("no database")
      })
      given("an empty basket", function(context) {
        stop("this step must not execute")
      })
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the error message includes "no database"
    And the steps and hooks have these results:
      | step                  | status  |
      | Before                | failed  |
      | Given an empty basket | skipped |

  Scenario: A failing after hook fails the scenario
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      after(function(context, scenario) {
        stop("can't close the database")
      })
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the output includes
      """
      v Given an empty basket
      Error:
      can't close the database

      """
    And the output includes
      """
      Failures

      Feature: Basket
      Scenario: Add an item
      v Given an empty basket
      Error:
      can't close the database
      """
    And the steps and hooks have these results:
      | step                  | status |
      | Given an empty basket | passed |
      | After                 | failed |

  Scenario: A failing after hook is reported after a failing step
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      after(function(context, scenario) stop("can't close the database"))
      given("an empty basket", function(context) stop("basket is broken"))
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the output includes
      """
      ! basket is broken
      Error:
      can't close the database
      """

  Scenario Outline: An after hook gets the status of a scenario with a step that is <case>, strict = <strict>
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      after(function(context, scenario) cat("after:", scenario$status, "\n"))
      <definitions>
      """
    When I run
      """
      test("features", strict = <strict>, stop_on_failure = FALSE)
      """
    Then the output includes "after: <case>"

    Examples:
      | case      | strict | definitions                                                                                   |
      | undefined | TRUE   |                                                                                               |
      | undefined | FALSE  |                                                                                               |
      | ambiguous | TRUE   | when("I add an item", function(context) {}); when("I add an {word}", function(w, context) {}) |
      | ambiguous | FALSE  | when("I add an item", function(context) {}); when("I add an {word}", function(w, context) {}) |

  Scenario: An after hook gets the result of the after hooks that ran before it
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      after(function(context, scenario) cat("after:", scenario$status, conditionMessage(scenario$error), "\n"))
      after(function(context, scenario) stop("can't close the database"))
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the output includes "after: failed can't close the database"

  Scenario Outline: A failing <hook>() hook fails the scenario
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      <hook>(function(context, <argument>) stop("the hook failed"))
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the error message includes "the hook failed"
    And the scenarios have these results:
      | scenario    | status |
      | Add an item | failed |
    And the steps have these results:
      | step                  | status   |
      | Given an empty basket | <status> |

    Examples:
      | hook        | argument | status  |
      | before      | scenario | skipped |
      | after       | scenario | passed  |
      | before_step | step     | failed  |
      | after_step  | step     | failed  |

  Scenario Outline: <hook>() with the wrong number of arguments is an error
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      <hook>(function(context, scenario, step) {})
      given("an empty basket", function(context) {})
      """
    When I run it and it fails
      """
      test("features")
      """
    Then it fails with "A `<hook>` hook must have <count> arguments."
    And it fails with "<usage>"

    Examples:
      | hook        | count  | usage                                      |
      | before      | 2      | Use `function(context, scenario)`.         |
      | after       | 2      | Use `function(context, scenario)`.         |
      | before_step | 2      | Use `function(context, step)`.             |
      | after_step  | 2      | Use `function(context, step)`.             |
      | before_all  | 0 or 1 | Use `function()` or `function(context)`.   |
      | after_all   | 0 or 1 | Use `function()` or `function(context)`.   |

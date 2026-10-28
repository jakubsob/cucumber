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

  Scenario: Hooks defined by a function or a loop all run
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        @db @api
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      connect <- function(service) {
        before(function(context, scenario) cat("connect", service, "\n"), tags = paste0("@", service))
      }
      connect("db")
      connect("api")
      for (service in c("db", "api")) local({
        name <- service
        after(function(context, scenario) cat("disconnect", name, "\n"))
      })
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features")
      """
    Then the output includes these lines in order:
      """
      connect db
      connect api
      disconnect api
      disconnect db
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

  Scenario: A printed scenario shows where it is, and in after hooks its status and error
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          When I add an item
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) print(scenario))
      after(function(context, scenario) print(scenario))
      when("I add an item", function(context) stop("basket is full"))
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the output includes these lines in order:
      """
      <scenario> "Add an item" (basket.feature:2)
      <scenario> "Add an item" (basket.feature:2) failed
      Step "I add an item" failed
      """

  Scenario: A scenario without tags has no tags
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) cat("tags:", deparse(scenario$tags), "\n"))
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features")
      """
    Then the output includes "tags: character(0)"

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
    And the errors are
      """
      [error] Scenario: Save the basket
      Error: Hook "Connect to the database" failed
      i Feature: basket.feature:2
      i Scenario: Save the basket
      i Hook defined at: setup-steps.R:1
      Caused by error:
      ! connection refused
      """

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
    Then the errors are
      """
      [error] Scenario: Add an item
      Error: Hook `before()` failed
      i Feature: basket.feature:2
      i Scenario: Add an item
      i Hook defined at: setup-steps.R:1
      Caused by error:
      ! no database
      """
    And the scenarios have these results:
      | scenario    | status |
      | Add an item | failed |
    And the steps and hooks have these results:
      | step                  | status  |
      | Before                | failed  |
      | Given an empty basket | skipped |

  Scenario: After hooks run after a failing before hook
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) stop("no database"))
      after(function(context, scenario) {})
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the steps and hooks have these results:
      | step                  | status  |
      | Before                | failed  |
      | Given an empty basket | skipped |
      | After                 | passed  |

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
    Then the steps and hooks have these results:
      | step                  | status |
      | Given an empty basket | passed |
      | After                 | failed |
    And the errors are
      """
      [error] Scenario: Add an item
      Error: Hook `after()` failed
      i Feature: basket.feature:2
      i Scenario: Add an item
      i Hook defined at: setup-steps.R:1
      Caused by error:
      ! can't close the database
      """

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
    Then the steps and hooks have these results:
      | step                  | status |
      | Given an empty basket | failed |
      | After                 | failed |
    And the output includes
      """
      ! basket is broken
      Error:
      Hook `after()` failed
      i Feature: basket.feature:2
      i Scenario: Add an item
      i Hook defined at: setup-steps.R:1
      Caused by error:
      ! can't close the database
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
    Then the output includes these lines in order:
      """
      after: <case>
      """
    And the scenarios have these results:
      | scenario    | status |
      | Add an item | <case> |

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
      after(function(context, scenario) {
        cat("after:", scenario$status, conditionMessage(scenario$error), "\n")
        cat("parent:", conditionMessage(scenario$error$parent), "\n")
      })
      after(function(context, scenario) stop("can't close the database"))
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the output includes
      """
      after: failed Hook `after()` failed
      i Feature: basket.feature:2
      i Scenario: Add an item
      i Hook defined at: setup-steps.R:5
      Caused by error:
      ! can't close the database
      """
    And the output includes "parent: can't close the database"

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
    Then the errors are
      """
      [error] Scenario: Add an item
      <headline>
      i Feature: basket.feature:2
      i Scenario: Add an item
      i Hook defined at: setup-steps.R:1
      Caused by error:
      ! the hook failed
      """
    And the scenarios have these results:
      | scenario    | status |
      | Add an item | failed |
    And the steps have these results:
      | step                  | status   |
      | Given an empty basket | <status> |

    Examples:
      | hook        | argument | status | headline                           |
      | after       | scenario | passed | Error: Hook `after()` failed       |
      | before_step | step     | failed | Error: Hook `before_step()` failed |
      | after_step  | step     | failed | Error: Hook `after_step()` failed  |

  Scenario Outline: A named <hook>() hook's error starts with its name
    Given a file named "features/basket.feature" with
      """
      Feature: Basket
        Scenario: Add an item
          Given an empty basket
      """
    And a file named "features/setup-steps.R" with
      """
      <hook>(function(context, <argument>) stop("the hook failed"), name = "Check the basket")
      given("an empty basket", function(context) {})
      """
    When I run
      """
      test("features", stop_on_failure = FALSE)
      """
    Then the errors are
      """
      [error] Scenario: Add an item
      Error: Hook "Check the basket" failed
      i Feature: basket.feature:2
      i Scenario: Add an item
      i Hook defined at: setup-steps.R:1
      Caused by error:
      ! the hook failed
      """

    Examples:
      | hook        | argument |
      | after       | scenario |
      | before_step | step     |
      | after_step  | step     |

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
    Then it fails with
      """
      Error in `source_dir()`:
      ! Failed to evaluate './setup-steps.R'.
      Caused by error in `<hook>()`:
      ! <a> `<hook>` hook must have <count> arguments.
      i <usage>
      """

    Examples:
      | hook        | a  | count  | usage                                    |
      | before      | A  | 2      | Use `function(context, scenario)`.       |
      | after       | An | 2      | Use `function(context, scenario)`.       |
      | before_step | A  | 2      | Use `function(context, step)`.           |
      | after_step  | An | 2      | Use `function(context, step)`.           |
      | before_all  | A  | 0 or 1 | Use `function()` or `function(context)`. |
      | after_all   | An | 0 or 1 | Use `function()` or `function(context)`. |

  Scenario: Several tag expressions of a hook are an error
    Given a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) {}, tags = c("@db", "@slow"))
      """
    When I run it and it fails
      """
      test("features")
      """
    Then it fails with
      """
      Error in `source_dir()`:
      ! Failed to evaluate './setup-steps.R'.
      Caused by error in `before()`:
      ! `tags` must be one tag expression.
      i Combine tag expressions with `and`, like `"@smoke and not @slow"`.
      """

  Scenario: A hook's name that isn't a string is an error
    Given a file named "features/setup-steps.R" with
      """
      before(function(context, scenario) {}, name = 1)
      """
    When I run it and it fails
      """
      test("features")
      """
    Then it fails with
      """
      Error in `source_dir()`:
      ! Failed to evaluate './setup-steps.R'.
      Caused by error in `before()`:
      ! `name` must be a string, or `NULL`.
      """

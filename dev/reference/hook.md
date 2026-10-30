# Hooks

Hooks run code at points of a run, typically for setup and teardown:
`before()` and `after()` each scenario, `before_step()` and
`after_step()` each step, `before_all()` and `after_all()` the whole
run. A `before()` or `after()` hook can skip the scenario with
[`skip_scenario()`](https://jakubsob.github.io/cucumber/dev/reference/skip_scenario.md).
Hooks don't run in a dry run.

## Usage

``` r
before(hook, tags = NULL, name = NULL)

after(hook, tags = NULL, name = NULL)

before_step(hook, tags = NULL, name = NULL)

after_step(hook, tags = NULL, name = NULL)

before_all(hook, name = NULL)

after_all(hook, name = NULL)
```

## Arguments

- hook:

  A function that will be run.

  - `before()` and `after()` hooks get the `context` and the `scenario`:
    a list with the scenario's `name`, `tags`, `uri` (the feature file),
    `line` (of the scenario, or of the example row of an outline) and
    `id`, unique in the run, and in `after()` hooks its `status` and
    `error`.

  - `before_step()` and `after_step()` hooks get the `context` and the
    `step`: a list with the step's `keyword`, `text`, `line`, and its
    `data_table` and `doc_string` if it has them, as its step definition
    gets them, and in `after_step()` hooks its `status` and `error`.

  - `before_all()` and `after_all()` hooks get no arguments, or a
    `context` to attach data to the report, see
    [attachments](https://jakubsob.github.io/cucumber/dev/reference/attachments.md).
    It isn't shared with scenarios: to share a connection or an app
    driver, keep it in an environment of a `setup-*.R` file.

- tags:

  A tag expression, e.g. `"@db and not @slow"`. The hook runs only for
  scenarios that match it. If `NULL`, it runs for every scenario.

- name:

  A name for the hook, shown in its error messages, e.g.
  `Hook "Connect to the database" failed`.

## Behavior

```
```

### Feature: Hooks

`before()` and `after()` run code before and after each scenario, like
opening and closing a connection. Define as many as you need: before
hooks run in the order they are defined, after hooks in the reverse
order. Hooks of several files are defined in the order the files are
loaded: the `helper-*.R` files, then the `setup-*.R` files, each in
alphabetical order. Where a hook is defined has no impact on what
scenarios it runs for. Give a hook a `name` to find it in error
messages. A failing before hook skips the scenario's steps and fails it.
After hooks run even when the scenario failed, and a failing after hook
fails it.

What a before hook does is invisible to people who only read the
features. For setup they should read, use a Background instead, and keep
before hooks for low-level work like starting a browser or emptying a
database.

#### Background:

- Given a package

#### Scenario: Before hooks run in definition order and after hooks in reverse order

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket
  ```

- And a file named "features/setup-steps.R" with

      before(function(context, scenario) cat("before 1\n"))
      before(function(context, scenario) cat("before 2\n"))
      after(function(context, scenario) cat("after 1\n"))
      after(function(context, scenario) cat("after 2\n"))
      given("an empty basket", function(context) cat("step\n"))

- When I run

      test("features")

- Then it passes

- And the output includes

      before 1
      before 2
      step
      after 2
      after 1

#### Scenario: Hooks get the scenario, and after hooks get its result

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    @smoke
    Scenario: Add an item
      Given an empty basket
      When I add an item
  ```

- And a file named "features/setup-steps.R" with

      before(function(context, scenario) {
        cat("before:", scenario$name, scenario$tags, basename(scenario$uri), "\n")
      })
      after(function(context, scenario) {
        cat("after:", scenario$status, conditionMessage(scenario$error), "\n")
      })
      given("an empty basket", function(context) {})
      when("I add an item", function(context) stop("basket is full"))

- When I run

      test("features", stop_on_failure = FALSE)

- Then the output includes

      before: Add an item @smoke basket.feature

- And the output includes

      after: failed Step "I add an item" failed

#### Scenario: Hooks get where the scenario is and its id

The line of an example of a Scenario Outline is the line of its row.
Each scenario has an id of its own.

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Empty basket
      Given an empty basket

    Scenario Outline: Add <n> items
      Given an empty basket

      Examples:
        | n |
        | 1 |
        | 2 |
  ```

- And a file named "features/setup-steps.R" with

      ids <- character()
      before(function(context, scenario) {
        ids <<- c(ids, scenario$id)
        cat(scenario$name, "at", paste0(basename(scenario$uri), ":", scenario$line), "\n")
      })
      after_all(function() cat(length(unique(ids)), "ids", "\n"))
      given("an empty basket", function(context) {})

- When I run

      test("features")

- Then the output includes these lines in order:

      Empty basket at basket.feature:2
      Add 1 items at basket.feature:10
      Add 2 items at basket.feature:11
      3 ids

#### Scenario: A named hook's errors start with its name

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Save the basket
      Given an empty basket
  ```

- And a file named "features/setup-steps.R" with

      before(function(context, scenario) stop("connection refused"), name = "Connect to the database")
      given("an empty basket", function(context) {})

- When I run

      test("features", stop_on_failure = FALSE)

- Then the steps and hooks have these results:

  |                                |         |
  |--------------------------------|---------|
  | step                           | status  |
  | Before Connect to the database | failed  |
  | Given an empty basket          | skipped |

- And the errors are

      [error] Scenario: Save the basket
      Error: Hook "Connect to the database" failed
      i Feature: basket.feature:2
      i Scenario: Save the basket
      i Hook defined at: setup-steps.R:1
      Caused by error:
      ! connection refused

#### Scenario: A failing before hook skips the steps and fails the scenario

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket
  ```

- And a file named "features/setup-steps.R" with

      before(function(context, scenario) {
        stop("no database")
      })
      given("an empty basket", function(context) {
        stop("this step must not execute")
      })

- When I run

      test("features", stop_on_failure = FALSE)

- Then the errors are

      [error] Scenario: Add an item
      Error: Hook `before()` failed
      i Feature: basket.feature:2
      i Scenario: Add an item
      i Hook defined at: setup-steps.R:1
      Caused by error:
      ! no database

- And the scenarios have these results:

  |             |        |
  |-------------|--------|
  | scenario    | status |
  | Add an item | failed |

- And the steps and hooks have these results:

  |                       |         |
  |-----------------------|---------|
  | step                  | status  |
  | Before                | failed  |
  | Given an empty basket | skipped |

Source: `tests/acceptance/hooks.feature`

```
```

### Feature: Tagged hooks

A hook with `tags` runs only for the scenarios that match its tag
expression, like `before(connect, tags = "@db")`. A step hook with
`tags` runs only for the steps of those scenarios.

#### Background:

- Given a package

#### Scenario: Tagged hooks run only for scenarios that match the tag expression

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    @db
    Scenario: Save the basket
      Given an empty basket

    Scenario: Add an item
      Given an empty basket
  ```

- And a file named "features/setup-steps.R" with

      before(function(context, scenario) cat("connect for", scenario$name, "\n"), tags = "@db")
      after(function(context, scenario) cat("disconnect for", scenario$name, "\n"), tags = "@db")
      given("an empty basket", function(context) {})

- When I run

      test("features")

- Then it passes

- And the output includes "connect for Save the basket"

- And the output includes "disconnect for Save the basket"

- And the output doesn't include "connect for Add an item"

- And the output doesn't include "disconnect for Add an item"

Source: `tests/acceptance/tagged_hooks.feature`

```
```

### Feature: Step hooks

`before_step()` and `after_step()` run code before and after each step.
They get the step, and after step hooks also get its result. They don't
run for skipped, undefined or ambiguous steps. A failing step hook fails
the step.

#### Background:

- Given a package

#### Scenario: Step hooks run around each step and after step hooks get its result

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket
      When I add an item
      Then the basket has 1 item
  ```

- And a file named "features/setup-steps.R" with

      before_step(function(context, step) cat("before:", step$keyword, step$text, "\n"))
      after_step(function(context, step) cat("after:", step$text, step$status, "\n"))
      given("an empty basket", function(context) {})
      when("I add an item", function(context) stop("basket is full"))
      then("the basket has {int} item", function(n, context) {})

- When I run

      test("features", stop_on_failure = FALSE)

- Then the output includes

      before: Given an empty basket
      after: an empty basket passed
      before: When I add an item
      after: I add an item failed

- And the steps have these results:

  |                            |         |
  |----------------------------|---------|
  | step                       | status  |
  | Given an empty basket      | passed  |
  | When I add an item         | failed  |
  | Then the basket has 1 item | skipped |

- And the output doesn't include "before: Then the basket has 1 item"

- And the output doesn't include "after: the basket has 1 item"

#### Scenario: Step hooks get where the step is, and its Data Table and Doc String

They get the Data Table and the Doc String as the step definition gets
them.

- Given a file named "features/basket.feature" with

  ```` gherkin
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
  ````

- And a file named "features/setup-steps.R" with

      before_step(function(context, step) {
        cat(step$text, "at line", step$line, "\n")
        if (!is.null(step$data_table)) cat("items:", step$data_table$item, "\n")
        if (!is.null(step$doc_string)) cat("note:", step$doc_string, "\n")
      })
      given("an empty basket", function(context) {})
      when("I add these items", function(table, context) {})
      when("I add a note", function(note, context) {})

- When I run

      test("features")

- Then the output includes these lines in order:

      an empty basket at line 3
      I add these items at line 4
      items: apple banana
      I add a note at line 8
      note: A gift

Source: `tests/acceptance/before_after_step_hooks.feature`

```
```

### Feature: Before all and after all hooks

`before_all()` and `after_all()` run code once, before the first
scenario and after the last one, like starting and stopping a server.
They take no arguments, or a `context` to attach data to the report,
which isn't shared with the scenarios. To share a connection or an app
driver between scenarios, keep it in an environment of a `setup-*.R`
file and hand it to each scenario in a `before()` hook. A failing
`before_all()` hook stops the run before any scenario, after the other
`before_all()` hooks ran. `after_all()` hooks run even when the run
failed, and a failing one fails the run.

#### Background:

- Given a package

#### Scenario: Before all and after all hooks run once for the whole run

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket

    Scenario: Remove an item
      Given an empty basket
  ```

- And a file named "features/setup-steps.R" with

      before_all(function() cat("start the server\n"))
      after_all(function() cat("stop the server\n"))
      before(function(context, scenario) cat("scenario\n"))
      given("an empty basket", function(context) {})

- When I run

      test("features")

- Then it passes

- And the output includes "start the server" once

- And the output includes "stop the server" once

- And the output includes these lines in order:

      start the server
      scenario
      scenario
      stop the server

Source: `tests/acceptance/before_after_all_hooks.feature`

## Examples

``` r
if (FALSE) { # \dontrun{
before(function(context, scenario) {
  context$session <- selenider::selenider_session()
})

after(function(context, scenario) {
  if (scenario$status == "failed") {
    selenider::take_screenshot(file = paste0(scenario$name, ".png"))
  }
  selenider::close_session(context$session)
})

# Attach a screenshot to the step that failed, see vignette("reporting")
after_step(function(context, step) {
  if (step$status == "failed") {
    file <- tempfile(fileext = ".png")
    context$app$get_screenshot(file)
    context$attach(readBin(file, "raw", file.size(file)), "image/png")
  }
})

before(function(context, scenario) {
  context$db <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
}, tags = "@db", name = "Connect to the database")

before(function(context, scenario) {
  if (!nzchar(Sys.getenv("API_KEY"))) skip_scenario("API_KEY is not set")
}, tags = "@api")

before_all(function() {
  options(warn = 2)
})
} # }
```

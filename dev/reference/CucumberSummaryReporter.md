# Summary Reporter for Cucumber

Prints only the summary of the run. The other cucumber reporters print
it at the end of the run too:
[CucumberProgressReporter](https://jakubsob.github.io/cucumber/dev/reference/CucumberProgressReporter.md),
[CucumberProgressBarReporter](https://jakubsob.github.io/cucumber/dev/reference/CucumberProgressBarReporter.md)
and
[CucumberPrettyReporter](https://jakubsob.github.io/cucumber/dev/reference/CucumberPrettyReporter.md).

    Failures:

    1) Scenario: Remove an item # basket.feature:6
        ✔ Given a basket with 2 apples
        ✖ When I remove 3 apples
        Error:
          Can't remove more apples than there are.

    ────────────────────────────────────────────────────────────────────────
    Summary
      2 scenarios (1 failed, 1 passed)
      6 steps (1 failed, 5 passed)
      0m00.153s (executing steps: 0m00.121s)
    ────────────────────────────────────────────────────────────────────────

The scenarios that failed, are ambiguous or undefined are listed under
Failures, those that are pending and the failed attempts of retried
scenarios under Warnings.

## Behavior

```
```

### Feature: Summary reporter

`CucumberSummaryReporter` prints only the summary of the run: the
scenarios that didn't pass, numbered and with where they are, then the
scenarios and steps counted by status and how long the run took.
Scenarios that failed, are ambiguous or undefined are Failures. Pending
scenarios, and failed attempts of retried scenarios, are Warnings.

#### Scenario: Only the summary is printed

- Given a package

- And a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket
      When I add 1 item

    Scenario: Remove an item
      Given an empty basket
      When I remove 1 item
  ```

- And a file named "features/setup-steps.R" with

      given("an empty basket", function(context) {})
      when("I add {int} item", function(n, context) {})
      when("I remove {int} item", function(n, context) stop("The basket is empty"))

- When I run

      test("features", reporter = CucumberSummaryReporter$new(), stop_on_failure = FALSE)

- Then the output includes

      Failures:1) Scenario: Remove an item # basket.feature:6
      v Given an empty basket
      x When I remove 1 item

- And the output includes these lines in order:

      x When I remove 1 item
      Summary
      2 scenarios (1 failed, 1 passed)
      4 steps (1 failed, 3 passed)

- And the output doesn't include "Scenario: Add an item"

- And the output doesn't include "Feature: Basket"

- And the output doesn't include "...."

#### Scenario: Pending scenarios and failed attempts that were retried are warnings

- Given a package

- And a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Pay
      Given I pay

    Scenario: Sync
      When I sync
  ```

- And a file named "features/setup-steps.R" with

      attempts <- 0
      given("I pay", function(context) pending())
      when("I sync", function(context) {
        attempts <<- attempts + 1
        if (attempts == 1) stop("The server is busy")
      })

- When I run

      test("features", reporter = CucumberSummaryReporter$new(), retry = 1, stop_on_failure = FALSE)

- Then the output includes these lines in order:

      Warnings:
      1) Scenario: Pay # basket.feature:2
      P Given I pay
      2) Scenario: Sync (attempt 1, retried) # basket.feature:5
      x When I sync
      Summary
      2 scenarios (1 pending, 1 passed)

- And the output doesn't include "Failures:"

#### Scenario: The summary ends with how long the run took, and how long its steps took

- Given a package

- And a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Wait for the basket
      When I wait
  ```

- And a file named "features/setup-steps.R" with

      when("I wait", function(context) Sys.sleep(0.2))

- When I run

      test("features", reporter = CucumberSummaryReporter$new())

- Then the output includes lines matching these patterns in order:

      ^1 step \(1 passed\)$
      ^0m00\.[2-9][0-9]{2}s \(executing steps: 0m00\.[2-9][0-9]{2}s\)$

#### Scenario: A run without scenarios counts no scenarios and no steps

- Given a package

- And a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
  ```

- When I run

      test("features", reporter = CucumberSummaryReporter$new())

- Then the output includes

      Summary
      0 scenarios
      0 steps

#### Scenario: A hook's error is printed in the summary where the hook ran

- Given a package

- And a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket
  ```

- And a file named "features/setup-steps.R" with

      before(function(context, scenario) stop("The shop is closed"))
      after(function(context, scenario) stop("The till is broken"))
      given("an empty basket", function(context) {})

- When I run

      test("features", reporter = CucumberSummaryReporter$new(), stop_on_failure = FALSE)

- Then the output includes these lines in order:

      Failures:
      1) Scenario: Add an item # basket.feature:2
      Hook `before()` failed
      ! The shop is closed
      - Given an empty basket
      Hook `after()` failed
      ! The till is broken

Source: `tests/acceptance/r-summary_reporter.feature`

## Super class

[`cucumber::CucumberReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.md)
-\> `CucumberSummaryReporter`

## Public fields

- `step_statuses`:

  Statuses of the reported steps

- `scenario_statuses`:

  Statuses of the finished scenarios

- `current_feature`:

  Name of the feature currently executing, like `"Feature: Basket"`

- `current_scenario`:

  Name of the scenario currently executing, like
  `"Scenario: Add an item"`

- `current_rule`:

  Name of the Rule of the scenario currently executing, like
  `"Rule: Removing items"`, or `NULL`

- `current_steps`:

  Steps executed so far in the current scenario

- `current_hooks`:

  Results of the current scenario's hooks that failed, are pending or
  skipped it

- `failures`:

  The scenarios that didn't pass or skip, printed as they finish by some
  reporters

- `issues`:

  The scenarios listed in the summary: those that didn't pass or skip,
  and the failed attempts of retried scenarios, in the order they
  finished

- `undefined_parameter_types`:

  Parameter types used by step definitions but not defined

- `num_colors`:

  Terminal color support captured at construction

- `unicode`:

  Whether the terminal shows Unicode symbols, captured at construction

- `dynamic`:

  Whether the terminal can redraw a line, captured at construction

- `width`:

  Width of the terminal, captured at construction

- `live`:

  The line drawn by `draw()`, redrawn after printing above it

## Methods

### Public methods

- [`CucumberSummaryReporter$new()`](#method-CucumberSummaryReporter-new)

- [`CucumberSummaryReporter$draw()`](#method-CucumberSummaryReporter-draw)

- [`CucumberSummaryReporter$clear()`](#method-CucumberSummaryReporter-clear)

- [`CucumberSummaryReporter$print_above()`](#method-CucumberSummaryReporter-print_above)

- [`CucumberSummaryReporter$print_failures_since()`](#method-CucumberSummaryReporter-print_failures_since)

- [`CucumberSummaryReporter$add_message()`](#method-CucumberSummaryReporter-add_message)

- [`CucumberSummaryReporter$add_warning()`](#method-CucumberSummaryReporter-add_warning)

- [`CucumberSummaryReporter$print_run_error()`](#method-CucumberSummaryReporter-print_run_error)

- [`CucumberSummaryReporter$print_counts()`](#method-CucumberSummaryReporter-print_counts)

- [`CucumberSummaryReporter$print_undefined_parameter_types()`](#method-CucumberSummaryReporter-print_undefined_parameter_types)

- [`CucumberSummaryReporter$print_failures()`](#method-CucumberSummaryReporter-print_failures)

- [`CucumberSummaryReporter$end_run()`](#method-CucumberSummaryReporter-end_run)

- [`CucumberSummaryReporter$clone()`](#method-CucumberSummaryReporter-clone)

Inherited methods

- [`cucumber::CucumberReporter$report()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.html#method-report)
- [`cucumber::CucumberReporter$start_run()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.html#method-start_run)

------------------------------------------------------------------------

### Method `new()`

Initialize the reporter

#### Usage

    CucumberSummaryReporter$new(file = NULL)

#### Arguments

- `file`:

  Path of a file to print to instead of the console, replaced by each
  run, or `NULL`. A relative path is relative to the working directory
  when the reporter is created. Its directory is created when the
  reporter is, if it doesn't exist.

------------------------------------------------------------------------

### Method `draw()`

Draw a line that is redrawn in place, like a progress bar, in a terminal
that can redraw a line

#### Usage

    CucumberSummaryReporter$draw(text)

#### Arguments

- `text`:

  The line

------------------------------------------------------------------------

### Method `clear()`

Clear the line drawn by `draw()`, to print below it what would be
printed over it

#### Usage

    CucumberSummaryReporter$clear()

------------------------------------------------------------------------

### Method `print_above()`

Print above the line drawn by `draw()`, then draw it again

#### Usage

    CucumberSummaryReporter$print_above(code)

#### Arguments

- `code`:

  Code that prints

------------------------------------------------------------------------

### Method `print_failures_since()`

Print the scenarios that didn't pass after the first `n` above the line
drawn by `draw()`

#### Usage

    CucumberSummaryReporter$print_failures_since(n)

#### Arguments

- `n`:

  Number of failures already printed

------------------------------------------------------------------------

### Method `add_message()`

Follow the run's features, scenarios, steps and hooks in its messages

#### Usage

    CucumberSummaryReporter$add_message(envelope)

#### Arguments

- `envelope`:

  A list with one element, named by the message's type

------------------------------------------------------------------------

### Method `add_warning()`

Print a warning as it's raised

#### Usage

    CucumberSummaryReporter$add_warning(warning)

#### Arguments

- `warning`:

  The warning

------------------------------------------------------------------------

### Method `print_run_error()`

Print the error that stopped the run

#### Usage

    CucumberSummaryReporter$print_run_error(error)

#### Arguments

- `error`:

  The error, or `NULL`

------------------------------------------------------------------------

### Method `print_counts()`

Print the scenarios and steps counted by status

#### Usage

    CucumberSummaryReporter$print_counts()

------------------------------------------------------------------------

### Method `print_undefined_parameter_types()`

Print each undefined parameter type, with the last step definition that
used it

#### Usage

    CucumberSummaryReporter$print_undefined_parameter_types()

------------------------------------------------------------------------

### Method `print_failures()`

Print the scenarios that didn't pass, numbered and with where they are:
under Failures those that failed, are ambiguous or undefined, under
Warnings those that are pending and the failed attempts that were
retried

#### Usage

    CucumberSummaryReporter$print_failures()

------------------------------------------------------------------------

### Method `end_run()`

Print the error that stopped the run, if any, and the summary

#### Usage

    CucumberSummaryReporter$end_run(error = NULL)

#### Arguments

- `error`:

  The error that stopped the run, or `NULL`

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    CucumberSummaryReporter$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
cucumber::test("tests/acceptance", reporter = cucumber::CucumberSummaryReporter$new())
} # }
```

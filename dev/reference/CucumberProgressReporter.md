# Progress Reporter for Cucumber

The default reporter. Prints one line for each feature, with its
scenarios counted by status, then the summary of
[CucumberSummaryReporter](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.md):

      |  F  P  U  S  OK | Feature
    ✔ |              3 | Addition

    Feature: Basket
      Scenario: Remove an item
        ✔ Given a basket with 2 apples
        ✖ When I remove 3 apples
          Error:
            Can't remove more apples than there are.
    ✖ |  1           2 | Basket [1.2s]

To see each step, use
[CucumberPrettyReporter](https://jakubsob.github.io/cucumber/dev/reference/CucumberPrettyReporter.md).

## Behavior

```
```

### Feature: Progress reporter

`CucumberProgressReporter` is the default reporter. Like testthat's
`ProgressReporter`, it prints one line for each feature, with its
scenarios counted by status: failed (F), pending (P), undefined (U),
skipped (S) and passed (OK). An ambiguous scenario counts as failed. A
feature that took a second or more shows how long it took. A scenario
that didn't pass is printed as soon as it finishes, and again in the
summary at the end. In a terminal that can redraw a line, a feature's
line is redrawn with a spinner after each step. Elsewhere, like in CI,
it's printed once the feature finishes.

#### Background:

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

    Scenario: Pay for the items
      Given an empty basket
      When I pay
  ```

- And a file named "features/checkout.feature" with

  ``` gherkin
  Feature: Checkout
    Scenario: Check out an empty basket
      Given an empty basket
  ```

- And a file named "features/setup-steps.R" with

      given("an empty basket", function(context) {})
      when("I add {int} item", function(n, context) {})
      when("I remove {int} item", function(n, context) stop("The basket is empty"))

#### Scenario: Each feature is a line with its scenarios counted by status

- When I run

      test("features", stop_on_failure = FALSE)

- Then the output includes

      |  F  P  U  S  OK | Feature

- And the output includes

      x |  1     1      1 | Basket

- And the output includes

      v |               1 | Checkout

#### Scenario: A scenario that didn't pass is printed when it finishes

- When I run

      test("features", stop_on_failure = FALSE)

- Then the output includes

  ``` gherkin
  Feature: Basket
  Scenario: Remove an item
  v Given an empty basket
  x When I remove 1 item
  ```

- And the output includes

      Scenario: Pay for the items
      v Given an empty basket
      U When I pay

- And the output includes

      4 scenarios (1 failed, 1 undefined, 2 passed)

#### Scenario: A scenario that didn't pass is printed before its feature's line, and again in the summary

- When I run

      test("features", stop_on_failure = FALSE)

- Then the output includes these lines in order:

      Scenario: Remove an item
      x When I remove 1 item
      x |  1     1      1 | Basket
      Failures:
      1) Scenario: Remove an item # basket.feature:6
      x When I remove 1 item

- And the output includes "x When I remove 1 item" 2 times

#### Scenario: A warning is printed as it's raised

- Given a file named "features/setup-hooks.R" with

      before(function(context, scenario) {
        if (scenario$name == "Add an item") warning("The shop is busy")
      })

- When I run it and it fails

      test("features")

- Then the output includes

      Warning:
      The shop is busy

#### Scenario: The error that stopped the run is printed

- Given a file named "features/setup-steps.R" with

      before_all(function() stop("the server didn't start"))
      given("an empty basket", function(context) {})

- When I run

      test("features", stop_on_failure = FALSE)

- Then the output includes

      Error:
      Hook `before_all()` failed
      i Hook defined at: setup-steps.R:1
      Caused by error:
      ! the server didn't start

- And the output includes

      0 scenarios

Source: `tests/acceptance/r-progress_reporter.feature`

## Super classes

[`cucumber::CucumberReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.md)
-\>
[`cucumber::CucumberSummaryReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.md)
-\> `CucumberProgressReporter`

## Public fields

- `header_printed`:

  Whether the header of the columns was printed

- `feature_first`:

  Index of the current feature's first scenario in `scenario_statuses`

- `feature_start`:

  When the current feature started

- `frames`:

  Frames of the spinner, captured at construction

- `frame`:

  Number of steps of the current feature finished, to turn the spinner

## Methods

### Public methods

- [`CucumberProgressReporter$new()`](#method-CucumberProgressReporter-new)

- [`CucumberProgressReporter$feature_statuses()`](#method-CucumberProgressReporter-feature_statuses)

- [`CucumberProgressReporter$feature_line()`](#method-CucumberProgressReporter-feature_line)

- [`CucumberProgressReporter$draw_feature()`](#method-CucumberProgressReporter-draw_feature)

- [`CucumberProgressReporter$clone()`](#method-CucumberProgressReporter-clone)

Inherited methods

- [`cucumber::CucumberReporter$report()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.html#method-report)
- [`cucumber::CucumberReporter$start_run()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.html#method-start_run)
- [`cucumber::CucumberSummaryReporter$add_message()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-add_message)
- [`cucumber::CucumberSummaryReporter$add_warning()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-add_warning)
- [`cucumber::CucumberSummaryReporter$clear()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-clear)
- [`cucumber::CucumberSummaryReporter$draw()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-draw)
- [`cucumber::CucumberSummaryReporter$end_run()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-end_run)
- [`cucumber::CucumberSummaryReporter$print_above()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-print_above)
- [`cucumber::CucumberSummaryReporter$print_counts()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-print_counts)
- [`cucumber::CucumberSummaryReporter$print_failures()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-print_failures)
- [`cucumber::CucumberSummaryReporter$print_failures_since()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-print_failures_since)
- [`cucumber::CucumberSummaryReporter$print_run_error()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-print_run_error)
- [`cucumber::CucumberSummaryReporter$print_undefined_parameter_types()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-print_undefined_parameter_types)

------------------------------------------------------------------------

### Method `new()`

Initialize the reporter

#### Usage

    CucumberProgressReporter$new(file = NULL)

#### Arguments

- `file`:

  Path of a file to print to instead of the console, replaced by each
  run, or `NULL`

------------------------------------------------------------------------

### Method `feature_statuses()`

Statuses of the current feature's finished scenarios

#### Usage

    CucumberProgressReporter$feature_statuses()

------------------------------------------------------------------------

### Method `feature_line()`

The current feature's line

#### Usage

    CucumberProgressReporter$feature_line(symbol)

#### Arguments

- `symbol`:

  The status column

------------------------------------------------------------------------

### Method `draw_feature()`

Draw the current feature's line with the spinner

#### Usage

    CucumberProgressReporter$draw_feature()

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    CucumberProgressReporter$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
cucumber::test("tests/acceptance", reporter = cucumber::CucumberProgressReporter$new())
} # }
```

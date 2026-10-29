# Progress Bar Reporter for Cucumber

Shows a bar of the steps and hooks run so far, redrawn in place:

    Feature: Basket
      Scenario: Remove an item
        ✔ Given a basket with 2 apples
        ✖ When I remove 3 apples
          Error: Can't remove more apples than there are.
    12/40 steps [==============                                         ]

## Behavior

```
```

### Feature: Progress bar reporter

`CucumberProgressBarReporter` shows a bar of the steps and hooks run so
far. A scenario that didn't pass is printed as soon as it finishes, and
the summary of the run at the end. The bar is drawn only in a terminal
that can redraw a line. Elsewhere, like in CI, only the scenarios that
didn't pass and the summary are printed.

#### Background:

- Given a package

- And a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Remove an item
      Given an empty basket
      When I remove 1 item

    Scenario: Add an item
      Given an empty basket
      When I add 1 item
  ```

- And a file named "features/setup-steps.R" with

      given("an empty basket", function(context) {})
      when("I add {int} item", function(n, context) {})
      when("I remove {int} item", function(n, context) stop("The basket is empty"))

#### Scenario: The bar counts the steps run

- When I run

      reporter <- withr::with_options(list(cli.dynamic = TRUE), CucumberProgressBarReporter$new())
      test("features", reporter = reporter, stop_on_failure = FALSE)

- Then the output includes "1/4 steps \["

- And the output includes "4/4 steps \["

#### Scenario: A scenario that didn't pass is printed when it finishes

- When I run

      test("features", reporter = CucumberProgressBarReporter$new(), stop_on_failure = FALSE)

- Then the output includes

  ``` gherkin
  Feature: Basket
  Scenario: Remove an item
  v Given an empty basket
  x When I remove 1 item
  ```

- And the output includes "The basket is empty"

- And the output doesn't include "Scenario: Add an item"

- And the output doesn't include "steps \["

- And the output includes

      2 scenarios (1 failed, 1 passed)
      4 steps (1 failed, 3 passed)

Source: `tests/acceptance/r-progress_bar_reporter.feature`

## Super classes

[`cucumber::CucumberReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.md)
-\>
[`cucumber::CucumberSummaryReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.md)
-\> `CucumberProgressBarReporter`

## Public fields

- `total`:

  Number of steps and hooks of the scenarios to run

- `current`:

  Number of steps and hooks that finished

## Methods

### Public methods

- [`CucumberProgressBarReporter$add_message()`](#method-CucumberProgressBarReporter-add_message)

- [`CucumberProgressBarReporter$draw_bar()`](#method-CucumberProgressBarReporter-draw_bar)

- [`CucumberProgressBarReporter$end_run()`](#method-CucumberProgressBarReporter-end_run)

- [`CucumberProgressBarReporter$clone()`](#method-CucumberProgressBarReporter-clone)

Inherited methods

- [`cucumber::CucumberReporter$report()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.html#method-report)
- [`cucumber::CucumberReporter$start_run()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.html#method-start_run)
- [`cucumber::CucumberSummaryReporter$add_warning()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-add_warning)
- [`cucumber::CucumberSummaryReporter$clear()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-clear)
- [`cucumber::CucumberSummaryReporter$draw()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-draw)
- [`cucumber::CucumberSummaryReporter$initialize()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-initialize)
- [`cucumber::CucumberSummaryReporter$print_above()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-print_above)
- [`cucumber::CucumberSummaryReporter$print_counts()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-print_counts)
- [`cucumber::CucumberSummaryReporter$print_failures()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-print_failures)
- [`cucumber::CucumberSummaryReporter$print_failures_since()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-print_failures_since)
- [`cucumber::CucumberSummaryReporter$print_run_error()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-print_run_error)
- [`cucumber::CucumberSummaryReporter$print_undefined_parameter_types()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.html#method-print_undefined_parameter_types)

------------------------------------------------------------------------

### Method `add_message()`

Count the steps and hooks of each scenario, and advance the bar when one
finishes

#### Usage

    CucumberProgressBarReporter$add_message(envelope)

#### Arguments

- `envelope`:

  A list with one element, named by the message's type

------------------------------------------------------------------------

### Method `draw_bar()`

Draw the bar

#### Usage

    CucumberProgressBarReporter$draw_bar()

------------------------------------------------------------------------

### Method `end_run()`

Clear the bar and print the error that stopped the run, if any, and the
scenarios and steps counted by status. The scenarios that didn't pass
were printed when they finished.

#### Usage

    CucumberProgressBarReporter$end_run(error = NULL)

#### Arguments

- `error`:

  The error that stopped the run, or `NULL`

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    CucumberProgressBarReporter$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
cucumber::test("tests/acceptance", reporter = cucumber::CucumberProgressBarReporter$new())
} # }
```

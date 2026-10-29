# Dots Reporter for Cucumber

Prints one character for each step and hook as it finishes, then the
summary of
[CucumberSummaryReporter](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.md):

    ......F--

    Failures:

    1) Scenario: Remove an item # basket.feature:6
        ✔ Given a basket with 2 apples
        ✖ When I remove 3 apples
        Error:
          Can't remove more apples than there are.

    ────────────────────────────────────────────────────────────────────────
    Summary
      3 scenarios (1 failed, 2 passed)
      9 steps (1 failed, 2 skipped, 6 passed)
      0m00.153s (executing steps: 0m00.121s)
    ────────────────────────────────────────────────────────────────────────

## Behavior

```
```

### Feature: Dots reporter

`CucumberDotsReporter` prints one character for each step and hook as it
finishes: `.` passed, `F` failed, `-` skipped, `P` pending, `U`
undefined and `A` ambiguous. At the end it prints the summary of the run
with the scenarios that didn't pass.

#### Background:

- Given a package

- And a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket
      When I add 1 item
      Then the basket has 1 item

    Scenario: Remove an item
      Given an empty basket
      When I remove 1 item
      Then the basket has 0 items
  ```

- And a file named "features/setup-steps.R" with

      given("an empty basket", function(context) context$items <- 0)
      when("I add {int} item", function(n, context) context$items <- context$items + n)
      when("I remove {int} item", function(n, context) {
        if (context$items < n) stop("The basket is empty")
        context$items <- context$items - n
      })
      then("the basket has {int} item(s)", function(n, context) expect_equal(context$items, n))

#### Scenario: Each step is printed as a character

- When I run

      test("features", reporter = CucumberDotsReporter$new(), stop_on_failure = FALSE)

- Then the output includes

      ....F-

- And the output includes

      2 scenarios (1 failed, 1 passed)
      6 steps (1 failed, 1 skipped, 4 passed)

#### Scenario: The scenarios that didn't pass are printed at the end

- When I run

      test("features", reporter = CucumberDotsReporter$new(), stop_on_failure = FALSE)

- Then the output includes

      Failures:1) Scenario: Remove an item # basket.feature:7
      v Given an empty basket
      x When I remove 1 item

- And the output includes "The basket is empty"

- And the output doesn't include "Scenario: Add an item"

#### Scenario: Pending, undefined and ambiguous steps are printed as characters too

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Statuses
    Scenario: Pending
      Given a pending step

    Scenario: Undefined
      Given an undefined step

    Scenario: Ambiguous
      Given the ambiguous step
  ```

- And a file named "features/setup-statuses.R" with

      before(function(context, scenario) {})
      given("a pending step", function(context) pending())
      given("the ambiguous step", function(context) {})
      given("the {word} step", function(word, context) {})

- When I run

      test("features", reporter = CucumberDotsReporter$new(), stop_on_failure = FALSE)

- Then the output includes

      .P.U.A

Source: `tests/acceptance/r-dots_reporter.feature`

## Super classes

[`cucumber::CucumberReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.md)
-\>
[`cucumber::CucumberSummaryReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberSummaryReporter.md)
-\> `CucumberDotsReporter`

## Methods

### Public methods

- [`CucumberDotsReporter$add_message()`](#method-CucumberDotsReporter-add_message)

- [`CucumberDotsReporter$end_run()`](#method-CucumberDotsReporter-end_run)

- [`CucumberDotsReporter$clone()`](#method-CucumberDotsReporter-clone)

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

Print a character for each step and hook that finished

#### Usage

    CucumberDotsReporter$add_message(envelope)

#### Arguments

- `envelope`:

  A list with one element, named by the message's type

------------------------------------------------------------------------

### Method `end_run()`

End the line of characters and print the summary

#### Usage

    CucumberDotsReporter$end_run(error = NULL)

#### Arguments

- `error`:

  The error that stopped the run, or `NULL`

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    CucumberDotsReporter$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
cucumber::test("tests/acceptance", reporter = cucumber::CucumberDotsReporter$new())
} # }
```

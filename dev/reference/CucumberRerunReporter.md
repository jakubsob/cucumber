# Cucumber Rerun Reporter

Writes where the scenarios that didn't pass are, like Cucumber's `rerun`
formatter: a line for each feature file, with the line of each of its
scenarios that didn't pass, like `basket.feature:3:12`. Pass them to the
`features` argument of
[`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md) to
run only those scenarios again. To also see the progress of the run,
combine it with another reporter in a
[CucumberMultiReporter](https://jakubsob.github.io/cucumber/dev/reference/CucumberMultiReporter.md).

## Behavior

```
```

### Feature: Rerun reporter

`CucumberRerunReporter` writes where the scenarios that didn't pass are,
like Cucumber's `rerun` formatter, when the run ends. Each line is a
feature file with the lines of its scenarios that didn't pass, like
`basket.feature:5:14`. Passed to `features`, they run only those
scenarios again.

#### Background:

- Given a package

- And a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given a step that passes

    Scenario: Remove an item
      Given a step that fails

    Scenario Outline: Pay with <card>
      Given a step that <result>

      Examples:
        | card | result |
        | visa | passes |
        | amex | fails  |
  ```

- And a file named "features/checkout.feature" with

  ``` gherkin
  Feature: Checkout
    Scenario: Ship
      Given a step that is pending
  ```

- And a file named "features/setup-steps.R" with

      given("a step that passes", function(context) {})
      given("a step that fails", function(context) stop("Failed"))
      given("a step that is pending", function(context) pending())

#### Scenario: Each feature file is a line with the scenarios that didn't pass

- When I run

      test("features", reporter = CucumberRerunReporter$new("rerun.txt"), stop_on_failure = FALSE)

- Then the file "rerun.txt" has these lines:

      basket.feature:5:14
      checkout.feature:2

#### Scenario: The scenarios that didn't pass run again

- When I run

      test("features", reporter = CucumberRerunReporter$new("rerun.txt"), stop_on_failure = FALSE)
      test("features", features = readLines("rerun.txt"), stop_on_failure = FALSE)

- Then the scenarios have these results:

  |                |         |
  |----------------|---------|
  | scenario       | status  |
  | Remove an item | failed  |
  | Pay with amex  | failed  |
  | Ship           | pending |

#### Scenario: A run of the scenarios of a rerun file writes the same rerun file

- When I run

      test("features", reporter = CucumberRerunReporter$new("rerun.txt"), stop_on_failure = FALSE)
      test("features", features = readLines("rerun.txt"), reporter = CucumberRerunReporter$new("rerun-2.txt"), stop_on_failure = FALSE)

- Then the file "rerun-2.txt" has these lines:

      basket.feature:5:14
      checkout.feature:2

#### Scenario: A scenario that passed when retried isn't in the file

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given a step that passes the second time

    Scenario: Remove an item
      Given a step that fails
  ```

- And a file named "features/setup-flaky.R" with

      attempts <- 0
      given("a step that passes the second time", function(context) {
        attempts <<- attempts + 1
        if (attempts < 2) stop("Not yet")
      })

- When I run

      test("features", reporter = CucumberRerunReporter$new("rerun.txt"), retry = 1, stop_on_failure = FALSE)

- Then the file "rerun.txt" has these lines:

      basket.feature:5
      checkout.feature:2

#### Scenario: The scenarios that fail_fast skipped are in the file

- When I run

      test("features", reporter = CucumberRerunReporter$new("rerun.txt"), fail_fast = TRUE, stop_on_failure = FALSE)

- Then the scenarios have these results:

  |                |         |
  |----------------|---------|
  | scenario       | status  |
  | Add an item    | passed  |
  | Remove an item | failed  |
  | Pay with visa  | skipped |
  | Pay with amex  | skipped |
  | Ship           | skipped |

- And the file "rerun.txt" has these lines:

      basket.feature:5:13:14
      checkout.feature:2

#### Scenario: Empty lines of a rerun file are ignored

Like a rerun file edited by hand, with an empty line at its end.

- When I run

      writeLines(c("basket.feature:5", "", " "), "rerun.txt")
      test("features", features = readLines("rerun.txt"), stop_on_failure = FALSE)

- Then the scenarios have these results:

  |                |        |
  |----------------|--------|
  | scenario       | status |
  | Remove an item | failed |

#### Scenario: The file is empty when every scenario passed

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given a step that passes
  ```

- And a file named "features/checkout.feature" with

  ``` gherkin
  Feature: Checkout
  ```

- When I run

      test("features", reporter = CucumberRerunReporter$new("rerun.txt"))

- Then the file "rerun.txt" is empty

#### Scenario: No scenario runs again when every scenario passed

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given a step that passes
  ```

- And a file named "features/checkout.feature" with

  ``` gherkin
  Feature: Checkout
  ```

- When I run

      test("features", reporter = CucumberRerunReporter$new("rerun.txt"))
      test("features", features = readLines("rerun.txt"))

- Then no scenario ran

Source: `tests/acceptance/r-rerun_reporter.feature`

## Super classes

[`cucumber::CucumberReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.md)
-\>
[`cucumber::CucumberQueryReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberQueryReporter.md)
-\> `CucumberRerunReporter`

## Public fields

- `file`:

  Path of the file the scenarios are written to

## Methods

### Public methods

- [`CucumberRerunReporter$new()`](#method-CucumberRerunReporter-new)

- [`CucumberRerunReporter$end_run()`](#method-CucumberRerunReporter-end_run)

- [`CucumberRerunReporter$clone()`](#method-CucumberRerunReporter-clone)

Inherited methods

- [`cucumber::CucumberReporter$add_warning()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.html#method-add_warning)
- [`cucumber::CucumberReporter$report()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.html#method-report)
- [`cucumber::CucumberQueryReporter$add_message()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberQueryReporter.html#method-add_message)
- [`cucumber::CucumberQueryReporter$start_run()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberQueryReporter.html#method-start_run)

------------------------------------------------------------------------

### Method `new()`

Create a rerun reporter

#### Usage

    CucumberRerunReporter$new(file = "rerun.txt")

#### Arguments

- `file`:

  Path of the file to write, replaced by each run. A relative path is
  relative to the working directory when the reporter is created. Its
  directory is created when the reporter is, if it doesn't exist.

------------------------------------------------------------------------

### Method `end_run()`

Write the scenarios that didn't pass

#### Usage

    CucumberRerunReporter$end_run(error = NULL)

#### Arguments

- `error`:

  The error that stopped the run, or `NULL`

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    CucumberRerunReporter$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
cucumber::test(reporter = cucumber::CucumberMultiReporter$new(list(
  cucumber::CucumberProgressReporter$new(),
  cucumber::CucumberRerunReporter$new("rerun.txt")
)))

# Run the scenarios that didn't pass again
cucumber::test(features = readLines("rerun.txt"))
} # }
```

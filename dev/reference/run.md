# Run Cucumber tests in a `testthat` context

Call `run()` in a `tests/testthat/test-*.R` file to run the feature
files alongside the package's `testthat` tests.

## Usage

``` r
run(
  path = ".",
  filter = NULL,
  tags = NULL,
  reporter = if (is.null(testthat::get_reporter())) CucumberProgressReporter$new(),
  strict = TRUE,
  dry_run = FALSE,
  name = NULL,
  features = NULL,
  fail_fast = FALSE,
  retry = 0,
  order = "defined",
  ...
)
```

## Arguments

- path:

  Path to the directory containing the `.feature` files. Its
  subdirectories are searched too. If `run()` is placed in a
  `tests/testthat/test-*.R` file and you call
  [`testthat::test_dir`](https://testthat.r-lib.org/reference/test_dir.html)
  or similar, it runs in the `tests/testthat` directory. The default
  value `"."` finds all feature files in the `tests/testthat` directory.

- filter:

  If not NULL, run only the feature files whose name matches this
  regular expression.

- tags:

  If not NULL, run only the scenarios that match this tag expression,
  e.g. `"@smoke and not @slow"`.

- reporter:

  A
  [CucumberReporter](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.md),
  or `NULL` to report nothing of its own. In a testthat run, it defaults
  to `NULL`, leaving the output to testthat's reporter, which reports
  each scenario as a test. Outside of one, like in the console, it
  defaults to
  [CucumberProgressReporter](https://jakubsob.github.io/cucumber/dev/reference/CucumberProgressReporter.md),
  as there is no testthat reporter to show the run.

- strict:

  If `FALSE`, pending and undefined steps don't fail the run.

- dry_run:

  If `TRUE`, match steps to step definitions without running steps or
  hooks.

- name:

  If not NULL, run only the scenarios whose name matches any of these
  regular expressions.

- features:

  If not NULL, run only these feature files, relative to `path`. A
  directory runs the feature files in it and its subdirectories. Add
  `:line` to run only the scenario at that line, e.g.
  `"addition.feature:12"`. An empty vector runs no scenario. Empty
  strings, like the empty lines of a rerun file, are ignored.

- fail_fast:

  If `TRUE`, skip the scenarios after the first failed scenario.

- retry:

  How many times to run a failed scenario again, until it passes. Only
  failed scenarios are retried, not pending, undefined or ambiguous
  ones.

- order:

  The order to run scenarios in: `"defined"`, the order of the feature
  files and of the scenarios in them, `"reverse"`, or `"random"`.
  `"random:<seed>"`, like `"random:1234"`, runs them in the random order
  of that seed. Without a seed, the seed is chosen and shown, to run
  them in the same order again.

- ...:

  Additional arguments passed to
  [`grepl()`](https://rdrr.io/r/base/grep.html).

## Value

NULL, invisibly.

## Details

Each `run()` is a run of its own: its
[`before_all()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
and
[`after_all()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
hooks run once for each `run()`, so twice if two test files call
`run()`. Step definitions, hooks and parameter types are kept until
testthat's run ends, as testthat runs the `setup-*.R` files that define
them once for all test files. Outside of a testthat run, like when
`run()` is called in the console, they're kept until `run()` returns,
and code deferred to
[`testthat::teardown_env()`](https://testthat.r-lib.org/reference/teardown_env.html)
runs when it returns. `run()` then attaches testthat for the steps'
expectations, runs every scenario, reports them with
[CucumberProgressReporter](https://jakubsob.github.io/cucumber/dev/reference/CucumberProgressReporter.md)
and fails with "Test failures." if one of them failed.

`run()` in a parallel testthat run, with
`Config/testthat/parallel: true`, is an error: testthat would delete the
snapshot files of its feature files as unused.

testthat runs the `setup-*.R` files before `run()`, so for them to
define steps without `cucumber::`, call
[`library(cucumber)`](https://github.com/jakubsob/cucumber) in
`tests/testthat.R`.

Skip scenarios in a
[`before_all()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
or
[`before()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
hook, not with `skip()` before `run()` in its test file: testthat
deletes the snapshot files of feature files that a run of every test
file didn't run.

To get the results of a run, use
[`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md),
which returns them like
[`testthat::test_dir()`](https://testthat.r-lib.org/reference/test_dir.html).

## Behavior

```
```

### Feature: Running scenarios alongside testthat tests

`run()` in a `tests/testthat/test-*.R` file runs the feature files in
`tests/testthat` as part of the package's testthat tests, e.g. with
[`testthat::test_local()`](https://testthat.r-lib.org/reference/test_package.html)
or `devtools::test()`. It chooses what to run like
[`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md),
with `filter`, `features`, `tags` and `name`. testthat's reporter
reports each scenario as a test of the test file that calls `run()`, and
a failed step by its text and a warning, at its line of the feature
file. Pass a `reporter` to `run()` to report the run with cucumber's
reporter too.

`run()` isn't supported in a parallel testthat run, with
`Config/testthat/parallel: true`: it's an error.

`run()` can also run feature files outside of a testthat run, like in
the console. It then attaches testthat for the steps' expectations, runs
every scenario and fails if one of them failed. Its step definitions and
hooks are cleared when it returns.

#### Background:

- Given a package

- And a file named "R/calculate.R" with

      calculate <- function(x) x + 1

- And a file named "tests/testthat/calculate.feature" with

  ``` gherkin
  Feature: Calculate
    Scenario: Adding one
      Given I calculate
      Then the result is 2
  ```

- And a file named "tests/testthat/test-acceptance.R" with

      run()

#### Scenario: Scenarios run with the package's testthat tests

- Given a file named "tests/testthat/setup-steps.R" with

      given("I calculate", function(context) {
        context$result <- calculate(1)
      })
      then("the result is {int}", function(n, context) {
        expect_equal(context$result, n)
      })

- And a file named "tests/testthat/test-calculate.R" with

      test_that("calculate adds one", {
        expect_equal(calculate(1), 2)
      })

- When I run

      testthat::test_local()

- Then it passes

- And it ran "Scenario: Adding one"

- And it ran "calculate adds one"

#### Scenario Outline: run() chooses what to run like test(), with \<argument\>

- Given a file named "tests/testthat/other.feature" with

  ``` gherkin
  Feature: Other
    @slow
    Scenario: Not run
      Given I calculate
  ```

- And a file named "tests/testthat/setup-steps.R" with

      given("I calculate", function(context) {
        context$result <- calculate(1)
      })
      then("the result is {int}", function(n, context) {
        expect_equal(context$result, n)
      })

- And a file named "tests/testthat/test-acceptance.R" with

      run(<argument> = "<value>")

- When I run

      testthat::test_local()

- Then only these scenarios ran:

  |            |
  |------------|
  | scenario   |
  | Adding one |

##### Examples:

|          |                   |
|----------|-------------------|
| argument | value             |
| filter   | calculate         |
| features | calculate.feature |
| tags     | not @slow         |
| name     | Adding one        |

#### Scenario: Each scenario is a test of the test file that calls run()

- Given a file named "tests/testthat/setup-steps.R" with

      given("I calculate", function(context) {
        context$result <- calculate(1)
      })
      then("the result is {int}", function(n, context) {
        expect_equal(context$result, n)
      })

- When I run

      testthat::test_local(reporter = "silent")

- Then the results are of these files:

  |            |                   |
  |------------|-------------------|
  | scenario   | file              |
  | Adding one | test-acceptance.R |

#### Scenario: testthat's reporter shows the line of the feature file where the step failed

- Given a file named "tests/testthat/setup-steps.R" with

      given("I calculate", function(context) {
        context$result <- calculate(1)
      })
      then("the result is {int}", function(n, context) {
        expect_equal(context$result, 3)
      })

- When I run

      testthat::test_local(reporter = "progress", stop_on_failure = FALSE)

- Then the scenarios failed at these locations:

  |            |                     |
  |------------|---------------------|
  | scenario   | location            |
  | Adding one | calculate.feature:4 |

#### Scenario: run() outside of a testthat run runs every scenario, and fails if one failed

Steps can use testthat's expectations, as `run()` attaches testthat.

- Given a file named "features/calculate.feature" with

  ``` gherkin
  Feature: Calculate
    Scenario: Adding one
      Then one plus 1 is 2

    Scenario: Adding two
      Then one plus 2 is 4

    Scenario: Adding three
      Then one plus 3 is 4
  ```

- And a file named "features/steps.R" with

      then("one plus {int} is {int}", function(n, sum, context) {
        expect_equal(1 + n, sum)
      })

- When I run outside of a testthat run and it fails

      source("features/steps.R")
      run("features")

- Then it fails with

      Error:
      ! Test failures.

- And the scenarios have these results:

  |              |        |
  |--------------|--------|
  | scenario     | status |
  | Adding one   | passed |
  | Adding two   | failed |
  | Adding three | passed |

#### Rule: Outside of a testthat run, run() reports the run with CucumberProgressReporter

As there is no testthat reporter to show it. Pass `reporter = NULL` to
report nothing.

##### Scenario: run() outside of a testthat run shows which step failed

- Given a file named "features/calculate.feature" with

  ``` gherkin
  Feature: Calculate
    Scenario: Adding one
      Then one plus 1 is 3
  ```

- And a file named "features/steps.R" with

      then("one plus {int} is {int}", function(n, sum, context) {
        expect_equal(1 + n, sum)
      })

- When I run outside of a testthat run and it fails

      source("features/steps.R")
      run("features")

- Then the output includes these lines in order:

      Scenario: Adding one
      x Then one plus 1 is 3
      Step "one plus 1 is 3" failed

##### Scenario: run() in a parallel testthat run is an error

- When I run

      withr::with_envvar(
        c(TESTTHAT_IS_PARALLEL = "true"),
        testthat::test_local(reporter = "silent", stop_on_failure = FALSE)
      )

- Then the errors are

      [error]
      Error: `run()` isn't supported in a parallel testthat run.
      i Set `Config/testthat/parallel: false` in DESCRIPTION, or run the feature files with `cucumber::test()`.

Source: `tests/acceptance/r-running_alongside_testthat.feature`

## See also

[snapshots](https://jakubsob.github.io/cucumber/dev/reference/snapshots.md)
for how snapshots of steps are saved and checked.

## Examples

``` r
if (FALSE) { # \dontrun{
#' tests/testthat/test-cucumber.R
cucumber::run()
} # }
```

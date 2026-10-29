# Run Cucumber tests

It runs tests from specifications in `.feature` files found in the
`path`.

To run Cucumber tests alongside `testthat` tests, see
[`cucumber::run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md).

## Usage

``` r
test(
  path = getOption("cucumber.path"),
  filter = NULL,
  tags = NULL,
  reporter = CucumberProgressReporter$new(),
  env = NULL,
  load_helpers = TRUE,
  stop_on_failure = TRUE,
  stop_on_warning = FALSE,
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
  subdirectories are searched too. Defaults to the `cucumber.path`
  option, see
  [opts](https://jakubsob.github.io/cucumber/dev/reference/opts.md).

- filter:

  If not NULL, run only the feature files whose name matches this
  regular expression.

- tags:

  If not NULL, run only the scenarios that match this tag expression,
  e.g. `"@smoke and not @slow"`.

- reporter:

  A
  [CucumberReporter](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.md),
  or `NULL` to report nothing. Defaults to
  [CucumberProgressReporter](https://jakubsob.github.io/cucumber/dev/reference/CucumberProgressReporter.md).

- env:

  Environment in which to run the tests, e.g. with step definitions and
  code sourced into it, for a project that isn't a package.

- load_helpers:

  Source helper files before running the tests?

- stop_on_failure:

  If `TRUE`, throw an error if any tests fail.

- stop_on_warning:

  If `TRUE`, throw an error if any tests generate warnings.

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
  [`grepl()`](https://rdrr.io/r/base/grep.html) to control filtering.

## Value

The results of the run, like
[`testthat::test_dir()`](https://testthat.r-lib.org/reference/test_dir.html),
invisibly.

## testthat's teardown environment

Like in
[`testthat::test_dir()`](https://testthat.r-lib.org/reference/test_dir.html),
what the `helper-*.R` and `setup-*.R` files, steps and hooks defer to
[`testthat::teardown_env()`](https://testthat.r-lib.org/reference/teardown_env.html),
like `withr::defer(DBI::dbDisconnect(con), teardown_env())`, runs when
`test()` ends, also when it's called in a testthat test file.

## test() in a testthat file

`test()` keeps the step definitions, hooks and parameter types
registered before it, like by the setup files of the testthat run, for
the test files after it. A setup file of `path` that testthat runs too,
like with `test(".")` in a file of `tests/testthat`, defines its step
definitions again rather than twice. `test(".")` in a file of
`tests/testthat` tells testthat which snapshot files its feature files
use, and is an error in a parallel testthat run.

## Good Practices

- Use a separate directory for your acceptance tests, e.g.
  `tests/acceptance`.

  It's not prohibited to use `tests/testthat` directory, but it's not
  recommended as those tests serve a different purpose and are better
  run separately, especially if acceptance tests take longer to run than
  unit tests.

  If you want to run Cucumber tests alongside `testthat` tests, you can
  use
  [`cucumber::run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md)
  in one of the `test-*.R` files in your `tests/testthat` directory.

- Use `test-*.R` files to test the support code you might have
  implemented that is used to run Cucumber tests.

  Those tests won't be run when calling `test()`. To run those tests use
  `testthat::test_dir("tests/acceptance")`.

## Behavior

```
```

### Feature: Running tests with test()

`test()` runs the feature files in `tests/acceptance`, or in the
directory set in the `cucumber.path` option. Pass `path` to run another
directory. A mistake in an argument is an error that says what is wrong.

#### Background:

- Given a package

- And a file named "tests/acceptance/addition.feature" with

  ``` gherkin
  Feature: Addition
    Scenario: Adding in tests/acceptance
      Given I have 1
      Then I get 1
  ```

- And a file named "features/addition.feature" with

  ``` gherkin
  Feature: Addition
    Scenario: Adding in features
      Given I have 1
      Then I get 1
  ```

- And a file named "tests/acceptance/setup-steps.R" with

      given("I have {int}", function(n, context) {
        context$value <- n
      })
      then("I get {int}", function(n, context) {
        expect_equal(context$value, n)
      })

- And a file named "features/setup-steps.R" with

      given("I have {int}", function(n, context) {
        context$value <- n
      })
      then("I get {int}", function(n, context) {
        expect_equal(context$value, n)
      })

#### Scenario: Feature files in tests/acceptance are run by default

- When I run

      test()

- Then only these scenarios ran:

  |                            |
  |----------------------------|
  | scenario                   |
  | Adding in tests/acceptance |

#### Scenario: Feature files are run from the directory set in the cucumber.path option

- When I run

      withr::with_options(list(cucumber.path = "features"), test())

- Then only these scenarios ran:

  |                    |
  |--------------------|
  | scenario           |
  | Adding in features |

Source: `tests/acceptance/r-running_tests.feature`

```
```

### Feature: Loading step definitions and support code

cucumber runs on testthat, so it loads files the way testthat does.
Files named `setup-*.R` and `helper-*.R` next to the feature files are
run before the scenarios: put step definitions, hooks and parameter
types in them, along with any code the steps need. Code of the package
under test is available once the package is loaded, e.g. with
[`pkgload::load_all()`](https://pkgload.r-lib.org/reference/load_all.html).

#### Background:

- Given a package

- And a file named "features/calculate.feature" with

  ``` gherkin
  Feature: Calculate
    Scenario: Adding one
      Given I calculate
      Then the result is 2
  ```

- And a file named "features/setup-steps.R" with

      given("I calculate", function(context) {
        context$result <- calculate(1)
      })
      then("the result is {int}", function(n, context) {
        expect_equal(context$result, n)
      })

#### Scenario: Code in a setup file is available in steps

- Given a file named "features/setup-calculate.R" with

      calculate <- function(x) x + 1

- When I run

      test("features")

- Then it passes

#### Scenario: Code of the loaded package is available in steps

- Given a file named "R/calculate.R" with

      calculate <- function(x) x + 1

- When I run

      pkgload::load_all(quiet = TRUE)
      test("features")

- Then it passes

Source: `tests/acceptance/r-support_code.feature`

```
```

### Feature: Testing projects that aren't packages

cucumber doesn't need a package. Step definitions can use code from
`box` modules (https://github.com/klmr/box), or code sourced into an
environment passed to `test(env = )`.

#### Rule: Steps can use box modules

##### Background:

- Given a file named "tests/acceptance/calculate.feature" with

  ``` gherkin
  Feature: Calculate
    Scenario: Adding one
      Given I add one to 1
      Then the result is 2

    Scenario: Adding two
      Given I add two to 1
      Then the result is 3
  ```

- And a file named "src/calculate.R" with

      #' @export
      add_one <- function(x) x + 1#' @export
      add_two <- function(x) x + 2

##### Scenario: Steps can use a box module

- Given a file named "tests/acceptance/setup-steps.R" with

      box::use(cucumber[given, then])
      box::use(../../src/calculate)given("I add one to {int}", function(x, context) {
        context$result <- calculate$add_one(x)
      })
      given("I add two to {int}", function(x, context) {
        context$result <- calculate$add_two(x)
      })
      then("the result is {int}", function(n, context) {
        expect_equal(context$result, n)
      })

- When I run

      box::purge_cache()
      test()

- Then the scenarios have these results:

  |            |        |
  |------------|--------|
  | scenario   | status |
  | Adding one | passed |
  | Adding two | passed |

#### Rule: Code sourced into an environment is available to steps

##### Scenario: Steps and code sourced into `env` are used by test()

- Given a file named "tests/calculate.feature" with

  ``` gherkin
  Feature: Calculate
    Scenario: Adding one
      Given I calculate
      Then the result is 2
  ```

- And a file named "src/calculate.R" with

      calculate <- function(x) x + 1

- And a file named "tests/steps.R" with

      given("I calculate", function(context) {
        context$result <- calculate(1)
      })
      then("the result is {int}", function(n, context) {
        expect_equal(context$result, n)
      })

- When I run

      env <- new.env()
      source("tests/steps.R", local = env)
      source("src/calculate.R", local = env)
      test("tests", env = env)

- Then it passes

Source: `tests/acceptance/r-projects_that_arent_packages.feature`

```
```

### Feature: Choosing feature files

`test(path)` runs every `.feature` and `.feature.md` file in `path`,
searched recursively. Run only some of them by listing them in
`features`, or with a `filter` on their file names.

#### Background:

- Given a package

- And a file named "features/addition.feature" with

  ``` gherkin
  Feature: Addition
    Scenario: Adding
      Given I have 1
      Then I get 1
  ```

- And a file named "features/math/subtraction.feature" with

  ``` gherkin
  Feature: Subtraction
    Scenario: Subtracting
      Given I have 2
      Then I get 2
  ```

- And a file named "features/math/advanced/division.feature" with

  ``` gherkin
  Feature: Division
    Scenario: Dividing
      Given I have 3
      Then I get 3
  ```

- And a file named "features/setup-steps.R" with

      given("I have {int}", function(n, context) {
        context$value <- n
      })
      then("I get {int}", function(n, context) {
        expect_equal(context$value, n)
      })

#### Scenario: Feature files in the directory and its subdirectories are run

- When I run

      test("features")

- Then only these scenarios ran:

  |             |
  |-------------|
  | scenario    |
  | Adding      |
  | Subtracting |
  | Dividing    |

#### Rule: `features` lists the feature files to run

##### Scenario: Only the listed feature files are run

- When I run

      test("features", features = c("addition.feature", "math/subtraction.feature"))

- Then only these scenarios ran:

  |             |
  |-------------|
  | scenario    |
  | Adding      |
  | Subtracting |

#### Rule: `filter` runs the feature files whose name matches a regular expression

The name is the file name without its `.feature` or `.feature.md`
extension. Extra arguments of `test()` are passed to
[`grepl()`](https://rdrr.io/r/base/grep.html).

##### Scenario: Only feature files whose name matches are run

- When I run

      test("features", filter = "^(addition|division)$")

- Then only these scenarios ran:

  |          |
  |----------|
  | scenario |
  | Adding   |
  | Dividing |

Source: `tests/acceptance/paths.feature`

```
```

### Feature: Running scenarios by tag

Run only the scenarios whose tags match a tag expression, like
`test(tags = "@smoke and not @slow")`. A tag expression combines tags
with `and`, `or`, `not` and parentheses, like the official
cucumber/tag-expressions. Tags are written with their `@`, and `and`,
`or` and `not` are lowercase. Scenarios inherit the tags of their
Feature and Rule, and examples inherit the tags of their Examples.

#### Background:

- Given a package

- And a file named "features/setup-steps.R" with

      given("I have {int}", function(n, context) {
        context$value <- n
      })
      then("I get {int}", function(n, context) {
        expect_equal(context$value, n)
      })

#### Rule: A tag expression selects the scenarios to run

##### Background:

- Given a file named "features/tagged.feature" with

  ``` gherkin
  Feature: Tagged
    @smoke @fast
    Scenario: Smoke and fast
      Given I have 1
      Then I get 1

    @smoke @slow
    Scenario: Smoke and slow
      Given I have 2
      Then I get 2

    @ui @fast
    Scenario: UI and fast
      Given I have 3
      Then I get 3

    @ui @slow
    Scenario: UI and slow
      Given I have 4
      Then I get 4

    Scenario: Untagged
      Given I have 5
      Then I get 5
  ```

##### Scenario: A single tag runs the scenarios that have it

- When I run

      test("features", tags = "@smoke")

- Then only these scenarios ran:

  |                |
  |----------------|
  | scenario       |
  | Smoke and fast |
  | Smoke and slow |

##### Scenario: "not" runs the scenarios that don't have the tag, untagged ones too

- When I run

      test("features", tags = "not @slow")

- Then only these scenarios ran:

  |                |
  |----------------|
  | scenario       |
  | Smoke and fast |
  | UI and fast    |
  | Untagged       |

##### Scenario: Parentheses group parts of an expression

- When I run

      test("features", tags = "(@smoke or @ui) and not @slow")

- Then only these scenarios ran:

  |                |
  |----------------|
  | scenario       |
  | Smoke and fast |
  | UI and fast    |

#### Rule: A tag in an expression is everything up to whitespace or a parenthesis

A backslash escapes a parenthesis, a whitespace or a backslash in a tag:
`@wip\(x\)` matches the tag `@wip(x)`. In an R string the backslash
itself is escaped: `tags = "@wip\\(x\\)"`.

##### Background:

- Given a file named "features/tagged.feature" with

  ``` gherkin
  Feature: Issues
    @BJ-x98.77
    Scenario: Issue tracker ID
      Given I have 1
      Then I get 1

    @team:payments
    Scenario: Team
      Given I have 2
      Then I get 2

    @and-more
    Scenario: Starts like an operator
      Given I have 3
      Then I get 3

    @wip(x)
    Scenario: With parentheses
      Given I have 4
      Then I get 4
  ```

##### Scenario: Parentheses in a tag are escaped with a backslash

- When I run

      test("features", tags = "@wip\\(x\\)")

- Then only these scenarios ran:

  |                  |
  |------------------|
  | scenario         |
  | With parentheses |

Source: `tests/acceptance/target_specific_scenarios_by_tag.feature`

```
```

### Feature: Running scenarios by name

Run only the scenarios whose name matches a regular expression, like
`test(name = "^Adding")`.

#### Background:

- Given a package

- And a file named "features/addition.feature" with

  ``` gherkin
  Feature: Addition
    Scenario: Adding small numbers
      Given I have 1
      Then I get 1

    Scenario: Adding big numbers
      Given I have 1000
      Then I get 1000

    Scenario Outline: Adding <n>
      Given I have <n>
      Then I get <n>

      Examples:
        | n |
        | 2 |
        | 3 |
  ```

- And a file named "features/subtraction.feature" with

  ``` gherkin
  Feature: Subtraction
    Scenario: Subtracting small numbers
      Given I have 1
      Then I get 1
  ```

- And a file named "features/setup-steps.R" with

      given("I have {int}", function(n, context) {
        context$value <- n
      })
      then("I get {int}", function(n, context) {
        expect_equal(context$value, n)
      })

#### Scenario: Only the scenarios whose name matches are run

- When I run

      test("features", name = "small")

- Then only these scenarios ran:

  |                           |
  |---------------------------|
  | scenario                  |
  | Adding small numbers      |
  | Subtracting small numbers |

#### Scenario: The name of an outline's example has its placeholders replaced

- When I run

      test("features", name = "Adding 3")

- Then only these scenarios ran:

  |          |
  |----------|
  | scenario |
  | Adding 3 |

Source: `tests/acceptance/target_specific_scenarios_by_name.feature`

```
```

### Feature: Running scenarios by line

Run only the scenarios at given lines of a feature file, like
`test(features = "addition.feature:2")`. Each line is the line of a
Scenario or an Examples row.

#### Background:

- Given a package

- And a file named "features/addition.feature" with

  ``` gherkin
  Feature: Addition
    Scenario: Adding small numbers
      Given I have 1
      Then I get 1

    Scenario: Adding big numbers
      Given I have 1000
      Then I get 1000

    Scenario Outline: Adding <n>
      Given I have <n>
      Then I get <n>

      Examples:
        | n |
        | 2 |
        | 3 |
  ```

- And a file named "features/subtraction.feature" with

  ``` gherkin
  Feature: Subtraction
    Scenario: Subtracting small numbers
      Given I have 1
      Then I get 1
  ```

- And a file named "features/setup-steps.R" with

      given("I have {int}", function(n, context) {
        context$value <- n
      })
      then("I get {int}", function(n, context) {
        expect_equal(context$value, n)
      })

#### Scenario: Only the scenario at the line is run

- When I run

      test("features", features = "addition.feature:6")

- Then only these scenarios ran:

  |                    |
  |--------------------|
  | scenario           |
  | Adding big numbers |

#### Scenario: Several lines and several files can be given

- When I run

      test("features", features = c("addition.feature:2:6", "subtraction.feature:2"))

- Then only these scenarios ran:

  |                           |
  |---------------------------|
  | scenario                  |
  | Adding small numbers      |
  | Adding big numbers        |
  | Subtracting small numbers |

#### Scenario: The line of a Scenario Outline runs all its examples

- When I run

      test("features", features = "addition.feature:10")

- Then only these scenarios ran:

  |          |
  |----------|
  | scenario |
  | Adding 2 |
  | Adding 3 |

#### Scenario: The line of an example row runs only that example

- When I run

      test("features", features = "addition.feature:17")

- Then only these scenarios ran:

  |          |
  |----------|
  | scenario |
  | Adding 3 |

Source: `tests/acceptance/target_specific_scenarios_by_line.feature`

```
```

### Feature: Strict mode

By default, pending and undefined steps fail the run. With
`strict = FALSE` they don't: their scenario is reported as pending or
undefined, and the steps after them are skipped. Ambiguous steps fail
either way.

#### Background:

- Given a package

#### Scenario: A pending step skips the scenario when not strict

- Given a file named "features/mixed.feature" with

  ``` gherkin
  Feature: Mixed
    Scenario: Implemented
      Given I have 1
      Then I get 1

    Scenario: Not yet implemented
      Given a step that is pending
  ```

- And a file named "features/setup-steps.R" with

      given("I have {int}", function(n, context) {
        context$value <- n
      })
      then("I get {int}", function(n, context) {
        expect_equal(context$value, n)
      })
      given("a step that is pending", function(context) {
        pending()
      })

- When I run

      test("features", strict = FALSE)

- Then the scenarios have these results:

  |                     |         |
  |---------------------|---------|
  | scenario            | status  |
  | Implemented         | passed  |
  | Not yet implemented | pending |

- And the scenarios skipped at these locations:

  |                     |                 |
  |---------------------|-----------------|
  | scenario            | location        |
  | Not yet implemented | mixed.feature:7 |

#### Scenario: An undefined step skips the scenario when not strict

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      When I add an item
  ```

- And a file named "features/setup-steps.R" with

      given("an empty basket", function(context) {})

- When I run

      test("features", strict = FALSE)

- Then the scenarios have these results:

  |             |           |
  |-------------|-----------|
  | scenario    | status    |
  | Add an item | undefined |

- And the scenarios skipped at these locations:

  |             |                  |
  |-------------|------------------|
  | scenario    | location         |
  | Add an item | basket.feature:3 |

#### Scenario: An ambiguous step fails the scenario even when not strict

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      When I add an item
  ```

- And a file named "features/setup-steps.R" with

      when("I add an item", function(context) {})
      when("I add an {word}", function(thing, context) {})

- When I run

      test("features", strict = FALSE, stop_on_failure = FALSE)

- Then the steps have these results:

  |                    |           |
  |--------------------|-----------|
  | step               | status    |
  | When I add an item | ambiguous |

Source: `tests/acceptance/strict_mode.feature`

```
```

### Feature: Dry run

`test(dry_run = TRUE)` matches every step to a step definition, but runs
neither steps nor hooks. Use it to find undefined and ambiguous steps
without running the scenarios. Undefined and ambiguous steps are
reported, but they don't fail a dry run: a scenario with one is skipped.

#### Scenario: A dry run doesn't run steps or hooks

- Given a package

- And a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket
      When I add an item
  ```

- And a file named "features/setup-steps.R" with

      before_all(function() stop("hooks must not run"))
      before(function(context, scenario) stop("hooks must not run"))
      before_step(function(context, step) stop("hooks must not run"))
      after_step(function(context, step) stop("hooks must not run"))
      after(function(context, scenario) stop("hooks must not run"))
      after_all(function() stop("hooks must not run"))
      given("an empty basket", function(context) {
        stop("steps must not run")
      })
      when("I add an item", function(context) {
        stop("steps must not run")
      })

- When I run

      test("features", dry_run = TRUE)

- Then the steps and hooks have these results:

  |                       |         |
  |-----------------------|---------|
  | step                  | status  |
  | Given an empty basket | skipped |
  | When I add an item    | skipped |

#### Scenario: A dry run reports undefined steps without failing

- Given a package

- And a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket
      When I add an item
  ```

- And a file named "features/setup-steps.R" with

      given("an empty basket", function(context) {
        stop("steps must not run")
      })

- When I run

      test("features", dry_run = TRUE)

- Then the steps have these results:

  |                       |           |
  |-----------------------|-----------|
  | step                  | status    |
  | Given an empty basket | skipped   |
  | When I add an item    | undefined |

- And the output includes

      when("I add an item", function(context) {

Source: `tests/acceptance/dryrun_mode.feature`

```
```

### Feature: Fail fast

Stop running scenarios after the first scenario that fails. The
scenarios after it are reported as skipped, and their hooks don't run.
With `retry`, a scenario fails only when its last attempt fails, so one
that passes when it's retried doesn't stop the run.

#### Background:

- Given a package

- And a file named "features/a.feature" with

  ``` gherkin
  Feature: A
    Scenario: Passing
      Given I have 1
      Then I get 1

    Scenario: Failing
      Given I have 1
      Then I get 2

    Scenario: After the failure
      Given I have 3
      Then I get 3
  ```

- And a file named "features/b.feature" with

  ``` gherkin
  Feature: B
    Scenario: In the next feature file
      Given I have 4
      Then I get 4
  ```

- And a file named "features/setup-steps.R" with

      given("I have {int}", function(n, context) {
        context$value <- n
      })
      then("I get {int}", function(n, context) {
        expect_equal(context$value, n)
      })
      before(function(context, scenario) {
        cat("before", scenario$name, "\n")
      })

#### Scenario: Scenarios after a failed scenario are skipped

- When I run

      test("features", fail_fast = TRUE, stop_on_failure = FALSE)

- Then the scenarios have these results:

  |                          |         |
  |--------------------------|---------|
  | scenario                 | status  |
  | Passing                  | passed  |
  | Failing                  | failed  |
  | After the failure        | skipped |
  | In the next feature file | skipped |

- And the output includes "before Failing"

- And the output doesn't include "before After the failure"

- And the output doesn't include "before In the next feature file"

#### Scenario: An undefined step fails fast in strict mode

- Given a file named "features/a.feature" with

  ``` gherkin
  Feature: A
    Scenario: Undefined
      Given an undefined step

    Scenario: After the undefined step
      Given I have 3
      Then I get 3
  ```

- When I run

      test("features", fail_fast = TRUE, stop_on_failure = FALSE)

- Then the scenarios have these results:

  |                          |           |
  |--------------------------|-----------|
  | scenario                 | status    |
  | Undefined                | undefined |
  | After the undefined step | skipped   |
  | In the next feature file | skipped   |

Source: `tests/acceptance/fail_fast.feature`

```
```

### Feature: Retry

A scenario that fails, like one that depends on a slow service, can be
run again with `retry`. It runs up to `retry` more times, until it
passes, and its last attempt is its result. Only failed scenarios are
retried: pending, undefined or ambiguous steps wouldn't pass on another
attempt.

#### Background:

- Given a package

- And a file named "features/setup-steps.R" with

      attempts <- 0
      given("a step that passes the second time", function(context) {
        attempts <<- attempts + 1
        if (attempts < 2) stop("Not yet")
      })
      given("a step that always fails", function(context) {
        stop("Never")
      })
      given("a step that always passes", function(context) {})
      given("a pending step", function(context) {
        pending()
      })
      before(function(context, scenario) {
        cat("before", scenario$name, "\n")
      })

#### Scenario: A failed scenario runs again until it passes

- Given a file named "features/flaky.feature" with

  ``` gherkin
  Feature: Flaky
    Scenario: Passes
      Given a step that always passes

    Scenario: Passes the second time
      Given a step that passes the second time

    Scenario: Always fails
      Given a step that always fails
  ```

- When I run

      test("features", retry = 2, stop_on_failure = FALSE)

- Then the scenarios have these results:

  |                        |        |          |
  |------------------------|--------|----------|
  | scenario               | status | attempts |
  | Passes                 | passed | 1        |
  | Passes the second time | passed | 2        |
  | Always fails           | failed | 3        |

#### Scenario: The summary counts only the last attempt of a scenario

- Given a file named "features/flaky.feature" with

  ``` gherkin
  Feature: Flaky
    Scenario: Passes the second time
      Given a step that passes the second time
  ```

- When I run

      test("features", retry = 1, reporter = CucumberSummaryReporter$new())

- Then the output includes "1 scenario (1 passed)"

- And the output includes "1 step (1 passed)"

Source: `tests/acceptance/retry.feature`

```
```

### Feature: Order

Scenarios run in the order they are defined: feature files in order of
their path, or in the order `features` lists them, and the scenarios of
each file from top to bottom. With `order`, they run in reverse or in
random order instead, which shows scenarios that pass only after another
one left something behind.

#### Background:

- Given a package

- And a file named "features/a.feature" with

  ``` gherkin
  Feature: A
    Scenario: A1
      Given a step

    Scenario: A2
      Given a step
  ```

- And a file named "features/b.feature" with

  ``` gherkin
  Feature: B
    Scenario: B1
      Given a step

    Scenario: B2
      Given a step
  ```

- And a file named "features/setup-steps.R" with

      given("a step", function(context) {})

#### Scenario: Scenarios of all features run in reverse order

- When I run

      test("features", order = "reverse")

- Then the scenarios have these results:

  |          |        |
  |----------|--------|
  | scenario | status |
  | B2       | passed |
  | B1       | passed |
  | A2       | passed |
  | A1       | passed |

#### Scenario: Scenarios of all features run in the random order of a seed

- When I run

      test("features", order = "random:1")

- Then the scenarios have these results:

  |          |        |
  |----------|--------|
  | scenario | status |
  | A1       | passed |
  | B1       | passed |
  | B2       | passed |
  | A2       | passed |

#### Scenario: A random order without a seed shows the seed to run the same order again

- When I run

      test("features", order = "random")

- Then the output includes "Running scenarios in random order. Use
  \`order = \\random:"

Source: `tests/acceptance/order.feature`

```
```

### Feature: Markdown with Gherkin

A `.feature.md` file is a Markdown document with Gherkin in it, which
reads well wherever Markdown is rendered. Its headers are the Feature,
Rule, Background, Scenario and Examples, its list items that start with
a step keyword are steps, its code blocks are Doc Strings and its tables
indented 2 to 5 spaces are Data Tables and Examples. Tags are in
backticks. The rest of the Markdown is ignored.

#### Background:

- Given a package

#### Scenario: A Markdown document runs like a feature file

- Given a file named "features/basket.feature.md" with

      # Feature: BasketA basket holds the items a customer wants to buy.
      This table isn't Gherkin, because it isn't indented:| item  | price |
      | ----- | ----- |
      | apple | 1     |## Scenario Outline: Add <n> apples* Given an empty basket
      * When I add <n> apples
      * Then the basket has <n> items### Examples:  | n |
        | - |
        | 1 |
        | 2 |

- And a file named "features/setup-steps.R" with

      given("an empty basket", function(context) {
        context$items <- 0
      })
      when("I add {int} apples", function(n, context) {
        context$items <- context$items + n
      })
      then("the basket has {int} items", function(n, context) {
        expect_equal(context$items, n)
      })

- When I run

      test("features")

- Then the steps have these results:

  |              |                             |        |
  |--------------|-----------------------------|--------|
  | scenario     | step                        | status |
  | Add 1 apples | Given an empty basket       | passed |
  | Add 1 apples | When I add 1 apples         | passed |
  | Add 1 apples | Then the basket has 1 items | passed |
  | Add 2 apples | Given an empty basket       | passed |
  | Add 2 apples | When I add 2 apples         | passed |
  | Add 2 apples | Then the basket has 2 items | passed |

#### Scenario: A code block is a Doc String and an indented table is a Data Table

The separator row under the header of a Markdown table isn't a row of
the Data Table.

- Given a file named "features/basket.feature.md" with

      # Feature: Basket## Scenario: Add items* Given these items:
        | item   | price |
        | ------ | ----: |
        | apple  | 1     |
        | banana | 2     |
      * When I add a note:
        ```json
        {"gift": true}
        ```

- And a file named "features/setup-steps.R" with

      given("these items:", function(table, context) {
        expect_equal(table$item, c("apple", "banana"))
      })
      when("I add a note:", function(note, context) {
        expect_equal(as.character(note), '{"gift": true}')
        expect_equal(attr(note, "media_type"), "json")
      })

- When I run

      test("features")

- Then the steps have these results:

  |                    |        |
  |--------------------|--------|
  | step               | status |
  | Given these items: | passed |
  | When I add a note: | passed |

#### Scenario: Tags are written in backticks

- Given a file named "features/basket.feature.md" with

      # Feature: Basket`@smoke`
      ## Scenario: Add an item* Given an empty basket## Scenario: Remove an item* Given an empty basket

- And a file named "features/setup-steps.R" with

      given("an empty basket", function(context) {})

- When I run

      test("features", tags = "@smoke")

- Then the scenarios have these results:

  |             |        |
  |-------------|--------|
  | scenario    | status |
  | Add an item | passed |

#### Scenario: A Rule and a Background are headers too

- Given a file named "features/basket.feature.md" with

      # Feature: Basket## Background:* Given an empty basket## Rule: Items are counted### Background:* When I add 1 apples### Scenario: Add an apple* Then the basket has 1 items

- And a file named "features/setup-steps.R" with

      given("an empty basket", function(context) {
        context$items <- 0
      })
      when("I add {int} apples", function(n, context) {
        context$items <- context$items + n
      })
      then("the basket has {int} items", function(n, context) {
        expect_equal(context$items, n)
      })

- When I run

      test("features")

- Then the steps have these results:

  |              |                             |        |
  |--------------|-----------------------------|--------|
  | scenario     | step                        | status |
  | Add an apple | Given an empty basket       | passed |
  | Add an apple | When I add 1 apples         | passed |
  | Add an apple | Then the basket has 1 items | passed |

Source: `tests/acceptance/markdown_with_gherkin.feature`

```
```

### Feature: Gherkin parse failure

A feature file that isn't valid Gherkin fails with its errors and their
line:column, up to 11 errors per file. Every feature file is parsed
before anything runs, so if any of them can't be parsed, no scenario
runs.

#### Background:

- Given a package

#### Scenario: Every error in a feature file is reported with its line and column

- Given a file named "features/broken.feature" with

      Feature: Broken
        Scenario: Junk between steps
          Given a step
          this line is not a step
          Then a step
        Scenario: A ragged table
          Given a step
            | a | b |
            | c |

- And a file named "features/setup-steps.R" with

      given("a step", function(context) {})

- When I run

      test("features", stop_on_failure = FALSE)

- Then the errors are

      [error]
      Error: Can't parse feature files
      x Parse error in "broken.feature" (4:5): expected: #EOF, #TableRow, #DocStringSeparator, #StepLine, #TagLine, #ExamplesLine, #ScenarioLine, #RuleLine, #Comment, #Empty, got 'this line is not a step'
      x Parse error in "broken.feature" (9:7): inconsistent cell count within the table

#### Scenario: No scenario runs when a feature file fails to parse, and every parse error is reported

- Given a file named "features/a.feature" with

      Parse Error

- And a file named "features/b.feature" with

  ``` gherkin
  Feature: Valid
    Scenario: A step
      Given a step
  ```

- And a file named "features/c.feature" with

      Parse Error

- And a file named "features/setup-steps.R" with

      given("a step", function(context) {})

- When I run

      test("features", stop_on_failure = FALSE)

- Then no scenario ran

- And the errors are

      [error]
      Error: Can't parse feature files
      x Parse error in "a.feature" (1:1): expected: #EOF, #Language, #TagLine, #FeatureLine, #Comment, #Empty, got 'Parse Error'
      x Parse error in "c.feature" (1:1): expected: #EOF, #Language, #TagLine, #FeatureLine, #Comment, #Empty, got 'Parse Error'

Source: `tests/acceptance/gherkin_parse_failure.feature`

```
```

### Feature: Running feature files like testthat runs test files

`test()` runs the feature files in `path` the way
[`testthat::test_dir()`](https://testthat.r-lib.org/reference/test_dir.html)
runs test files: in `path` as the working directory, with the testthat
edition and the package of `path` as
[`testthat::testing_package()`](https://testthat.r-lib.org/reference/is_testing.html),
the package
[`testthat::local_mocked_bindings()`](https://testthat.r-lib.org/reference/local_mocked_bindings.html)
mocks and whose internal functions steps see, of the loaded package or
in R CMD check of the installed one, after the `helper-*.R` and
`setup-*.R` files, and before the `teardown-*.R` files. Steps can use
testthat's expectations, and
[`testthat::is_testing()`](https://testthat.r-lib.org/reference/is_testing.html)
is `TRUE` in them. A step or a hook fails when a `test_that()` test in
it fails. With the 3rd edition, steps run with testthat's reproducible
output, like its tests, and their messages are shown, while the 2nd
edition hides them. What the setup files and steps defer to
[`testthat::teardown_env()`](https://testthat.r-lib.org/reference/teardown_env.html)
runs when `test()` ends. Each feature file is the file of its scenarios'
results, and a failure, a skip or a warning is at its line: the line of
its step, or of its scenario for a hook. Outside of a testthat run, like
in the console, `test()` sets `NOT_CRAN` to `"true"` when it isn't set,
like
[`testthat::test_local()`](https://testthat.r-lib.org/reference/test_package.html),
so snapshots are checked. In a testthat run or in R CMD check,
`NOT_CRAN` is left as it is, so `skip_on_cran()` still skips on CRAN.
`skip()` in a
[`before_all()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
hook skips every scenario, like `skip()` at the top of a test file skips
its tests. `skip()` in a setup or helper file stops the run instead,
like in
[`testthat::test_dir()`](https://testthat.r-lib.org/reference/test_dir.html).
`test()` writes no test file into `path`, and doesn't run its `test-*.R`
files: they can test the code the steps use, with
[`testthat::test_dir()`](https://testthat.r-lib.org/reference/test_dir.html).

#### Background:

- Given a package

- And a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Adding an apple
      Given an empty basket
      When I add an apple
      Then the basket has 1 item
  ```

- And a file named "features/setup-steps.R" with

      given("an empty basket", function(context) {
        context$items <- 0
      })
      when("I add an apple", function(context) {
        context$items <- context$items + 1
      })
      then("the basket has {int} item(s)", function(n, context) {
        expect_equal(context$items, n)
      })

#### Scenario: Steps run in the directory of the feature files

- Given a file named "features/basket.txt" with

      apple

- And a file named "features/setup-basket.R" with

      given("the basket in basket.txt", function(context) {
        context$items <- length(readLines("basket.txt"))
      })

- And a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Reading the basket
      Given the basket in basket.txt
      Then the basket has 1 item
  ```

- When I run

      test("features")

- Then the scenarios have these results:

  |                    |        |
  |--------------------|--------|
  | scenario           | status |
  | Reading the basket | passed |

#### Scenario: A step fails when a test_that() test in it fails

- Given a file named "features/setup-test.R" with

      then("the basket is checked by a test", function(context) {
        test_that("the basket is empty", expect_equal(context$items, 0))
      })

- And a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Checking the basket with a test
      Given an empty basket
      When I add an apple
      Then the basket is checked by a test
  ```

- When I run

      test("features", stop_on_failure = FALSE)

- Then the steps have these results:

  |                                      |        |
  |--------------------------------------|--------|
  | step                                 | status |
  | Given an empty basket                | passed |
  | When I add an apple                  | passed |
  | Then the basket is checked by a test | failed |

- And the errors are

      [failure] Scenario: Checking the basket with a test / the basket is empty
      Expected `context$items` to equal 0.
      Differences:
      1/1 mismatches
      [1] 1 - 0 == 1[failure] Scenario: Checking the basket with a test
      Step "the basket is checked by a test" failed
      i Feature: basket.feature:5
      i Scenario: Checking the basket with a test
      i Step defined at: setup-test.R:1
      The test "the basket is empty" in the step failed.

- And the scenarios failed at these locations:

  |                                                       |                  |
  |-------------------------------------------------------|------------------|
  | scenario                                              | location         |
  | Checking the basket with a test / the basket is empty | basket.feature:5 |
  | Checking the basket with a test                       | basket.feature:5 |

#### Scenario: testthat::testing_package() is the package of the feature files

- Given a file named "features/setup-package.R" with

      then("the package under test is {string}", function(name, context) {
        expect_equal(testthat::testing_package(), name)
      })

- And a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Checking the package
      Then the package under test is "example"
  ```

- When I run

      test("features")

- Then the scenarios have these results:

  |                      |        |
  |----------------------|--------|
  | scenario             | status |
  | Checking the package | passed |

#### Scenario: What setup files and steps defer to testthat::teardown_env() runs when test() ends

- Given a file named "features/setup-log.R" with

      withr::defer(cat("setup file deferred\n", file = "../log.txt", append = TRUE), teardown_env())
      after(function(context, scenario) cat("after scenario\n", file = "../log.txt", append = TRUE))
      then("the basket is put away when the tests end", function(context) {
        withr::defer(cat("step deferred\n", file = "../log.txt", append = TRUE), teardown_env())
        succeed()
      })

- And a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Putting the basket away
      Then the basket is put away when the tests end
  ```

- When I run outside of a testthat run

      test("features")

- Then the scenarios have these results:

  |                         |        |
  |-------------------------|--------|
  | scenario                | status |
  | Putting the basket away | passed |

- And the file "log.txt" has these lines:

      after scenario
      step deferred
      setup file deferred

#### Scenario: A failure is at its line of the feature file, the line of its step or of its scenario

- Given a file named "features/setup-hooks.R" with

      before(function(context, scenario) {
        if (scenario$name == "Paying for an apple") stop("The till is closed")
      })

- And a file named "features/checkout/payment.feature" with

  ``` gherkin
  Feature: Payment
    Scenario: Paying for an apple
      Given an empty basket
  ```

- And a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Adding an apple
      Given an empty basket
      Then the basket has 1 item
  ```

- When I run

      test("features", stop_on_failure = FALSE)

- Then the scenarios failed at these locations:

  |                     |                            |
  |---------------------|----------------------------|
  | scenario            | location                   |
  | Adding an apple     | basket.feature:4           |
  | Paying for an apple | checkout/payment.feature:2 |

Source: `tests/acceptance/r-running_like_testthat.feature`

```
```

### Feature: Running tests more than once

Step definitions, hooks and parameter types are registered when the
setup files are loaded, and cleared when the run ends, even if a setup
file fails. Running the tests again in the same R session registers them
anew, instead of making every step ambiguous. Those registered before
`test()`, like by the setup files of a testthat run that calls it, are
kept. A file loaded again, like a setup file that testthat and
`test(".")` both run, defines its step definitions, hooks and parameter
types again rather than twice.

#### Scenario: Tests can be run twice in the same session

- Given a package

- And a file named "features/calculate.feature" with

  ``` gherkin
  Feature: Calculate
    Scenario: Adding one
      Given I calculate 1
      Then the result is 2
  ```

- And a file named "features/setup-steps.R" with

      define_parameter_type(name = "number", regexp = "\\d+", transformer = as.numeric)
      before(function(context, scenario) context$add <- (context$add %||% 0) + 1)
      given("I calculate {number}", function(x, context) {
        context$result <- x + context$add
      })
      then("the result is {int}", function(n, context) {
        expect_equal(context$result, n)
      })

- When I run

      test("features")
      test("features")

- Then it passes

- And the steps have these results:

  |                      |        |
  |----------------------|--------|
  | step                 | status |
  | Given I calculate 1  | passed |
  | Then the result is 2 | passed |

#### Scenario: A setup file loaded again defines its step definitions, hooks and parameter types again, not twice

- Given a package

- And a file named "features/calculate.feature" with

  ``` gherkin
  Feature: Calculate
    Scenario: Adding one
      Given I calculate 1
      Then the result is 2
  ```

- And a file named "features/setup-steps.R" with

      define_parameter_type(name = "number", regexp = "\\d+", transformer = as.numeric)
      before(function(context, scenario) {})
      given("I calculate {number}", function(x, context) {
        context$result <- x + 1
      })
      then("the result is {int}", function(n, context) {
        expect_equal(context$result, n)
      })

- When I run

      source("features/setup-steps.R", keep.source = TRUE)
      test("features")

- Then the steps and hooks have these results:

  |                      |        |
  |----------------------|--------|
  | step                 | status |
  | Before               | passed |
  | Given I calculate 1  | passed |
  | Then the result is 2 | passed |

Source: `tests/acceptance/r-running_twice.feature`

## Examples

``` r
if (FALSE) { # \dontrun{
cucumber::test("tests/acceptance")
cucumber::test("tests/acceptance", filter = "addition|multiplication")

# Scenarios by name or by line
cucumber::test("tests/acceptance", name = "^Adding")
cucumber::test("tests/acceptance", features = "addition.feature:12")

# Tag expressions
cucumber::test("tests/acceptance", tags = "@smoke")
cucumber::test("tests/acceptance", tags = "@smoke and @fast")
cucumber::test("tests/acceptance", tags = "@wip and not @slow")
cucumber::test("tests/acceptance", tags = "(@smoke or @ui) and (not @slow)")

# Find undefined steps without running anything
cucumber::test("tests/acceptance", dry_run = TRUE)
} # }
```

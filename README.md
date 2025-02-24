
# cucumber <img src="man/figures/logo.png" align="right" alt="" width="120" />

<!-- badges: start -->
[![R-CMD-check](https://github.com/jakubsob/cucumber/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/jakubsob/cucumber/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/jakubsob/cucumber/branch/main/graph/badge.svg)](https://app.codecov.io/gh/jakubsob/cucumber?branch=main)
[![CRAN status](https://www.r-pkg.org/badges/version/cucumber)](https://CRAN.R-project.org/package=cucumber)
[![Grand total](http://cranlogs.r-pkg.org/badges/grand-total/cucumber)](https://cran.r-project.org/package=cucumber)
[![Last month](http://cranlogs.r-pkg.org/badges/last-month/cucumber)](https://cran.r-project.org/package=cucumber)
<!-- badges: end -->

An implementation of the [Cucumber](https://cucumber.io/) testing framework in R. Fully native, no external dependencies.

Use it as an extension of your `testthat` tests or as a standalone testing stage.

## Introduction

The package parses [Gherkin](https://cucumber.io/docs/gherkin/reference/) documents

```gherkin
# tests/testthat/addition.feature
Feature: Addition
  Scenario: Adding 2 integers
    When I add 1 and 1
    Then the result is 2
  Scenario: Adding integer and float
    When I add 1 and 1.1
    Then the result is 2.1
  Scenario: Adding float and float
    When I add 1.1 and 1.1
    Then the result is 2.2
```

and uses step definitions to run the tests

```r
# tests/testthat/steps/steps_definitions.R
when("I add {int} and {int}", function(x, y, context) {
  context$result <- x + y
})

then("the result is {int}", function(expected, context) {
  expect_equal(context$result, expected)
})

when("I add {int} and {float}", function(x, y, context) {
  context$result <- x + y
})

when("I add {float} and {float}", function(x, y, context) {
  context$result <- x + y
})

then("the result is {float}", function(expected, context) {
  expect_equal(context$result, expected)
})
```

### Running cucumber tests with `testthat` tests.

To run `cucumber` as a part of `testthat` suite, create a `test-cucumber.R` file:

```r
#' tests/testthat/test-cucumber.R
cucumber::test(".", "./steps")
```

When you run:
- `testthat::test_dir("tests/testthat")`,
- `testthat::test_file("tests/testthat/test-cucumber.R")`,
- or `devtools::test()`,

it will use the [testthat reporter](https://testthat.r-lib.org/reference/Reporter.html) to show the results.


The building blocks of the cucumber tests are Features and Scenarios.
- Each Feature will be treated as a separate [context](https://testthat.r-lib.org/reference/context.html?q=context#ref-usage) – their results will be reported as if they were `test-*.R` files, e.g. `'test-Feature: Addition.R'`.
- Each Scenario is equivalent to a `testthat::test_that` or `testthat::it` case. You get feedback on each Scenario separately. Only if all steps in a scenario are successful, the scenario is considered successful.

That means a succesful run for an `Addition` feature would produce the following output (with [ProgressReporter](https://testthat.r-lib.org/reference/ProgressReporter.html)).

```r
| v | F W  S  OK | Context           |
| v | 3          | Feature: Addition |
== Results ================================================
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 3 ]
```

And if it doesn't succeed, it will report which Scenarios failed in the Feature.

```r
| v | F W  S  OK | Context           |
| x | 2        1 | Feature: Addition |
--------------------------------------------------------------------------------
Failure ('test-cucumber.R:1:1'): Scenario: Adding integer and float
context$result (`actual`) not equal to `expected` (`expected`).
`actual`: 2
`expected`: 5
Backtrace:
x
1. \-global `<step>`(expected = 5L, context = `<env>`)
2.   \-testthat::expect_equal(context$result, expected) at ./steps/addition.R:7:2
Failure ('test-cucumber.R:1:1'): Scenario: Adding float and float
context$result (`actual`) not equal to `expected` (`expected`).
`actual`: 2
`expected`: 5
Backtrace:
x
1. \-global `<step>`(expected = 5L, context = `<env>`)
2.   \-testthat::expect_equal(context$result, expected) at ./steps/addition.R:7:2
--------------------------------------------------------------------------------
== Results =====================================================================
-- Failed tests ----------------------------------------------------------------
Failure ('test-cucumber.R:1:1'): Scenario: Adding integer and float
context$result (`actual`) not equal to `expected` (`expected`).
`actual`: 2
`expected`: 5
Backtrace:
x
1. \-global `<step>`(expected = 5L, context = `<env>`)
2.   \-testthat::expect_equal(context$result, expected) at ./steps/addition.R:7:2
Failure ('test-cucumber.R:1:1'): Scenario: Adding float and float
context$result (`actual`) not equal to `expected` (`expected`).
`actual`: 2
`expected`: 5
Backtrace:
x
1. \-global `<step>`(expected = 5L, context = `<env>`)
2.   \-testthat::expect_equal(context$result, expected) at ./steps/addition.R:7:2
[ FAIL 1 | WARN 0 | SKIP 0 | PASS 2 ]
```

## Running cucumber tests separately to unit tests

If you want to run cucumber tests separately, for example as a different testing step on CI, just put `cucumber` tests in other directory (or use [testthat::test_dir filter parameter](https://testthat.r-lib.org/reference/test_dir.html)).

This may be especially useful, if `cucumber` tests are significantly slower than unit tests. It may often be the case as `cucumber` tests should target integration of different parts of the system and provide a high level confirmation if the system works as expected.

```
├── tests/
│   ├── cucumber/
│   │   ├── steps/
│   │   │   ├── feature_1_steps.R
│   │   │   ├── feature_2_steps.R
│   │   ├── feature_1.feature
│   │   ├── feature_2.feature
│   │   ├── test-cucumber.R
│   ├── testthat/
│   │   ├── test-unit_test_1.R
│   │   ├── test-unit_test_2.R
```

In that case you would run `cucumber` tests with `testthat::test_dir("tests/cucumber")`.

## Examples

See the [examples directory](https://github.com/jakubsob/cucumber/tree/main/inst/examples) to help you get started.

## How it works

The `.feature` files are parsed and matched against step definitions.

Step functions are defined using:
- `description`: a [cucumber expression](https://github.com/cucumber/cucumber-expressions).
- and an implementation function. It must have the parameters that will be matched in the description and a `context` parameter - an environment for managing state between steps.

If a step parsed from one of `.feature` files is not found, an error will be thrown.

### Parameter types

Step implementations receive data from the `.feature` files as parameters. The values are detected via regular expressions and casted with a transformer function.

The following parameter types are available by default:

| Parameter Type | Description                                                                                                                                                                                                   |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `{int}`        | Matches integers, for example `71` or `-19`. Converts value with `as.integer`.                                                                                                                                |
| `{float}`      | Matches floats, for example `3.6`, `.8` or `-9.2`. Converts value with `as.double`.                                                                                                                           |
| `{word}`       | Matches words without whitespace, for example banana (but not banana split).                                                                                                                                  |
| `{string}`     | Matches single-quoted or double-quoted strings, for example "banana split" or 'banana split' (but not banana split). Only the text between the quotes will be extracted. The quotes themselves are discarded. |

See `cucumber::define_parameter_type()` how to define your own parameter types.

## Supported Gherkin syntax:

- [x] Feature
- [x] Scenario
- [x] Example
- [x] Given
- [x] When
- [x] Then
- [x] And
- [x] But
- [x] *
- [x] Background
- [x] Scenario Outline (or Scenario Template)
- [x] Examples (or Scenarios)
- [ ] Rule
- [x] `"""` (Doc Strings)
- [x] `|` (Data Tables)
- [ ] `@` (Tags)
- [x] `#` (Comments)
- [x] Free-format text
- [ ] Localization

# Installation

To install the stable version from CRAN:

```r
install.packages("cucumber")
```

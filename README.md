
<!-- README.md is generated from README.Rmd. Please edit that file -->

# cucumber <img src="man/figures/logo.png" align="right" alt="" width="120" />

<!-- badges: start -->

[![R-CMD-check](https://github.com/jakubsob/cucumber/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/jakubsob/cucumber/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/jakubsob/cucumber/branch/main/graph/badge.svg)](https://app.codecov.io/gh/jakubsob/cucumber?branch=main)
[![cucumber](https://img.shields.io/github/actions/workflow/status/jakubsob/cucumber/test-acceptance.yaml?branch=main&label=cucumber&logo=cucumber&color=23D96C&labelColor=0f2a13)](https://github.com/jakubsob/cucumber/actions/workflows/test-acceptance.yaml)
[![muttest](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/jakubsob/cucumber/badges/badges/muttest.json)](https://github.com/jakubsob/cucumber/actions/workflows/test-mutation.yaml)
[![CRAN
status](https://www.r-pkg.org/badges/version/cucumber)](https://CRAN.R-project.org/package=cucumber)
[![Grand
total](http://cranlogs.r-pkg.org/badges/grand-total/cucumber)](https://cran.r-project.org/package=cucumber)
[![Last
month](http://cranlogs.r-pkg.org/badges/last-month/cucumber)](https://cran.r-project.org/package=cucumber)
<!-- badges: end -->

An implementation of the [Cucumber](https://cucumber.io/) testing
framework in R.

## Introduction

The package parses
[Gherkin](https://cucumber.io/docs/gherkin/reference/) documents

``` gherkin
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

``` r
when("I add {float} and {float}", function(x, y, context) {
  context$result <- x + y
})

then("the result is {float}", function(expected, context) {
  expect_equal(context$result, expected)
})
```

The building blocks of the cucumber tests are Features and Scenarios.

- Each Feature will be treated as a separate
  [context](https://testthat.r-lib.org/reference/context.html?q=context#ref-usage)
  – their results will be reported as if they were `test-*.R` files,
  e.g. `'test-Feature: Addition.R'`.
- Each Scenario is equivalent to a `testthat::test_that` or
  `testthat::it` case. You get feedback on each Scenario separately.
  Only if all steps in a scenario are successful, the scenario is
  considered successful.

Run the tests with `cucumber::test()`. By default it uses the
`CucumberProgressReporter`, which prints a line for each feature with
its scenarios counted by status:

``` r
withr::with_dir(pass_dir, {
  cucumber::test(filter = "addition")
})
```

      |  F  P  U  S  OK | Feature
    v |               3 | Addition

    --------------------------------------------------------------------------------
    Summary
      3 scenarios (3 passed)
      6 steps (6 passed)
    --------------------------------------------------------------------------------

When a step fails, the reporter shows which step broke and why as soon
as its scenario finishes, and again in the summary at the end:

``` r
withr::with_dir(fail_dir, {
  cucumber::test(filter = "addition")
})
```

      |  F  P  U  S  OK | Feature

    Feature: Addition
      Scenario: Adding integer and float
        v When I add 1 and 1.1
        x Then the result is 5
          Expected `context$result` to equal `expected`.
          Differences:
            `actual`: 2.1
          `expected`: 5.0
          
          Step at: setup-steps-addition.R:5

    Feature: Addition
      Scenario: Adding float and float
        v When I add 1.1 and 1.1
        x Then the result is 5
          Expected `context$result` to equal `expected`.
          Differences:
            `actual`: 2.2
          `expected`: 5.0
          
          Step at: setup-steps-addition.R:5
    x |  2            1 | Addition

    --------------------------------------------------------------------------------
    Summary
      3 scenarios (2 failed, 1 passed)
      6 steps (2 failed, 4 passed)
    --------------------------------------------------------------------------------

    Failures

    Feature: Addition
      Scenario: Adding integer and float
        v When I add 1 and 1.1
        x Then the result is 5
          Expected `context$result` to equal `expected`.
          Differences:
            `actual`: 2.1
          `expected`: 5.0
          
          Step at: setup-steps-addition.R:5

    Feature: Addition
      Scenario: Adding float and float
        v When I add 1.1 and 1.1
        x Then the result is 5
          Expected `context$result` to equal `expected`.
          Differences:
            `actual`: 2.2
          `expected`: 5.0
          
          Step at: setup-steps-addition.R:5

    Error:
    ! Test failures.

To see every step as it runs, use `CucumberPrettyReporter`.
`CucumberDotsReporter`, `CucumberProgressBarReporter` and
`CucumberSummaryReporter`.

``` r
withr::with_dir(pass_dir, {
  cucumber::test(filter = "addition", reporter = cucumber::CucumberPrettyReporter$new())
})
```


    Feature: Addition
      Scenario: Adding 2 integers
        v When I add 1 and 1
        v Then the result is 2
      Scenario: Adding integer and float
        v When I add 1 and 1.1
        v Then the result is 2.1
      Scenario: Adding float and float
        v When I add 1.1 and 1.1
        v Then the result is 2.2


    --------------------------------------------------------------------------------
    Summary
      3 scenarios (3 passed)
      6 steps (6 passed)
    --------------------------------------------------------------------------------

Put your acceptance tests in a directory separate to your unit tests:

``` text
tests/
├── acceptance/
│   ├── setup-steps_1.R
│   ├── setup-steps_2.R
│   ├── feature_1.feature
│   ├── feature_2.feature
├── testthat/
│   ├── test-unit_test_1.R
│   ├── test-unit_test_2.R
```

or alongside your unit tests:

``` text
tests/
├── testthat/
│   ├── test-cucumber.R
│   ├── test-unit_test_1.R
│   ├── test-unit_test_2.R
│   ├── setup-steps_1.R
│   ├── setup-steps_2.R
│   ├── feature_1.feature
│   ├── feature_2.feature
```

## Examples

See the [examples
directory](https://github.com/jakubsob/cucumber/tree/main/inst/examples)
to help you get started.

## Reports

Write the official Cucumber HTML report of a run with
`CucumberHtmlReporter`, and its JUnit XML report with
`CucumberJunitReporter`. Steps and hooks attach screenshots and logs to
it, like those of a failing
[shinytest2](https://rstudio.github.io/shinytest2/) scenario: see the
[Reports
article](https://jakubsob.github.io/cucumber/articles/reporting.html)
and [its
report](https://jakubsob.github.io/cucumber/shinytest2-report.html).

## Scenarios as documentation

Feature files already say how your package behaves, so let them document
it. Tag the scenarios that illustrate a function with `@rd`

``` gherkin
Feature: Basket
  A basket holds the items a customer wants to buy.

  @rd
  Scenario: Add an item
    Given an empty basket
    When I add 1 item
    Then the basket has 1 item

  Scenario: Remove an item from an empty basket
    Given an empty basket
    When I remove 1 item
    Then the basket is empty
```

and put them in its help page with `features_rd()`:

``` r
#' Add items to a basket
#' @eval cucumber::features_rd(features = "basket.feature")
#' @export
add <- function(basket, n) basket + n
```

`devtools::document()` adds a Specification section to `?add` with the
feature’s description and the tagged scenarios:

    Add items to a basket

    Description:

         Add items to a basket

    Usage:

         add(basket, n)
         
    Specification:

      Basket:

           A basket holds the items a customer wants to buy.

           Scenario: Add an item
             Given an empty basket
             When I add 1 item
             Then the basket has 1 item
           
           Source: 'tests/acceptance/basket.feature'

The help pages of this package are written this way, see
[`?hook`](https://jakubsob.github.io/cucumber/reference/hook.html) or
[`?test`](https://jakubsob.github.io/cucumber/reference/test.html): the
scenarios that test cucumber explain it, and stay true because they run.

## How it works

The `.feature` files are parsed and matched against step definitions.

Step functions are defined using:

- `description`: a [cucumber
  expression](https://github.com/cucumber/cucumber-expressions).
- and an implementation function. It must have the parameters that will
  be matched in the description and a `context` parameter - an
  environment for managing state between steps.

Text in a description is matched literally, except for:

- `{int}` and other [parameter types](#parameter-types), whose values
  are passed to the implementation,
- `(s)` – optional text: `"I have {int} cucumber(s)"` matches both
  `I have 1 cucumber` and `I have 2 cucumbers`,
- `a/b` – alternative words: `"I press the Enter/Return key"` matches
  either word.

To match `(`, `{` or `/` literally, escape them with a backslash,
e.g. `"a\\/b"`. An invalid expression, like `"I visit /about"`, is an
error.

A description that starts with `^`, ends with `$` or is surrounded by
`/` is a regular expression instead,
e.g. `"^I have (\\d+) cucumbers?$"`. Each capture group is passed to the
implementation.

Each step parsed from the `.feature` files must match exactly one step
definition. If a step matches none, an error with a ready-to-paste
snippet is thrown. If it matches more than one, an error listing every
matching definition is thrown.

### Parameter types

Step implementations receive data from the `.feature` files as
parameters. The values are detected via regular expressions and cast
with a transformer function.

The following parameter types are available by default:

| Parameter Type | Description |
|----|----|
| `{int}` | Matches integers, for example `71` or `-19`. Converts value with `as.integer`. |
| `{float}` | Matches floats, for example `3.6`, `.8`, `-9.2` or `1.5E3`, and integers like `12`. Converts value with `as.double`. |
| `{word}` | Matches words without whitespace, for example banana or foo-bar (but not banana split). |
| `{string}` | Matches single-quoted or double-quoted strings, for example “banana split” or ‘banana split’ (but not banana split). Only the text between the quotes will be extracted, with escaped quotes unescaped. |
| `{}` | Matches anything. Passes the matched text as is. |

See `cucumber::define_parameter_type()` how to define your own parameter
types.

## Installation

To install the stable version from CRAN:

``` r
install.packages("cucumber")
```

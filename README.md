
# cucumber <img src="man/figures/logo.png" align="right" alt="" width="120" />

<!-- badges: start -->
[![R-CMD-check](https://github.com/jakubsob/cucumber/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/jakubsob/cucumber/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/jakubsob/cucumber/branch/main/graph/badge.svg)](https://app.codecov.io/gh/jakubsob/cucumber?branch=main)
[![cucumber](https://img.shields.io/github/actions/workflow/status/jakubsob/cucumber/test-acceptance.yaml?branch=dev&label=cucumber&logo=cucumber&color=23D96C&labelColor=0f2a13)](https://github.com/jakubsob/cucumber/actions/workflows/test-acceptance.yaml)
[![muttest](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/jakubsob/cucumber/badges/badges/muttest.json)](https://github.com/jakubsob/cucumber/actions/workflows/test-mutation.yaml)
[![CRAN status](https://www.r-pkg.org/badges/version/cucumber)](https://CRAN.R-project.org/package=cucumber)
[![Grand total](http://cranlogs.r-pkg.org/badges/grand-total/cucumber)](https://cran.r-project.org/package=cucumber)
[![Last month](http://cranlogs.r-pkg.org/badges/last-month/cucumber)](https://cran.r-project.org/package=cucumber)
<!-- badges: end -->

An implementation of the [Cucumber](https://cucumber.io/) testing framework in R.

## Introduction

The package parses [Gherkin](https://cucumber.io/docs/gherkin/reference/) documents

```gherkin
# tests/acceptance/addition.feature
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
  Scenario: Adding float and float with signs
    When I add +11.1 and +11.1
    Then the result is +22.2
  Scenario: Adding float and float of opposite signs
    When I add +11.11 and -11.1
    Then the result is +0.01
```

and uses step definitions to run the tests

```r
# tests/acceptance/setups-steps.R
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

The building blocks of the cucumber tests are Features and Scenarios.

- Each Feature will be treated as a separate [context](https://testthat.r-lib.org/reference/context.html?q=context#ref-usage) – their results will be reported as if they were `test-*.R` files, e.g. `'test-Feature: Addition.R'`.
- Each Scenario is equivalent to a `testthat::test_that` or `testthat::it` case. You get feedback on each Scenario separately. Only if all steps in a scenario are successful, the scenario is considered successful.

That means a successful run for an `Addition` feature would produce the following output (with [ProgressReporter](https://testthat.r-lib.org/reference/ProgressReporter.html)).

```r
✔ | F W  S  OK | Context
✔ |          5 | Feature: Addition

══ Results ═══════════════════════════════════════════
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 5 ]
```

and a failing one would produce:

```r
✔ | F W  S  OK | Context
✖ | 1        4 | Feature: Addition
────────────────────────────────────────────────────────────────────────────
Failure (test-__cucumber__.R:2:1): Scenario: Adding float and float of opposite signs
context$result (`actual`) not equal to `expected` (`expected`).

  `actual`: 0.0100
`expected`: 0.0010
Backtrace:
    ▆
 1. └─cucumber (local) call() at cucumber/R/parse_token.R:23:13
 2.   └─cucumber (local) x(context = context, ...)
 3.     └─step(expected = 0.001, ...)
 4.       └─testthat::expect_equal(context$result, expected) at tests/acceptance/setup-steps-addition.R:19:3
────────────────────────────────────────────────────────────────────────────

══ Results ═════════════════════════════════════════════════════════════════
── Failed tests ────────────────────────────────────────────────────────────
Failure (test-__cucumber__.R:2:1): Scenario: Adding float and float of opposite signs
context$result (`actual`) not equal to `expected` (`expected`).

  `actual`: 0.0100
`expected`: 0.0010
Backtrace:
    ▆
 1. └─cucumber (local) call() at cucumber/R/parse_token.R:23:13
 2.   └─cucumber (local) x(context = context, ...)
 3.     └─step(expected = 0.001, ...)
 4.       └─testthat::expect_equal(context$result, expected) at tests/acceptance/setup-steps-addition.R:19:3

[ FAIL 1 | WARN 0 | SKIP 0 | PASS 4 ]
```

Put your acceptance tests in a directory separate to your unit tests:

```text
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

## Examples

See the [examples directory](https://github.com/jakubsob/cucumber/tree/main/inst/examples) to help you get started.

## How it works

The `.feature` files are parsed and matched against step definitions.

Step functions are defined using:

- `description`: a [cucumber expression](https://github.com/cucumber/cucumber-expressions).
- and an implementation function. It must have the parameters that will be matched in the description and a `context` parameter - an environment for managing state between steps.

If a step parsed from one of `.feature` files is not found, an error will be thrown.

### Parameter types

Step implementations receive data from the `.feature` files as parameters. The values are detected via regular expressions and cast with a transformer function.

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

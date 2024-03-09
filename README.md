
# cucumber <img src="man/figures/logo.png" align="right" alt="" width="120" />

<!-- badges: start -->
[![R-CMD-check](https://github.com/jakubsob/cucumber/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/jakubsob/cucumber/actions/workflows/R-CMD-check.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![Codecov test coverage](https://codecov.io/gh/jakubsob/cucumber/branch/main/graph/badge.svg)](https://app.codecov.io/gh/jakubsob/cucumber?branch=main)
<!-- badges: end -->

An implementation of the [Cucumber](https://cucumber.io/) testing framework in R. Fully native, no external dependencies.

Run with the rest of your `testthat` tests or as a standalone test suite.

## Introduction

The package parses Gherkin documents and allows you to write tests as shown below:

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

To run as a part of `testthat` suite, create a `test-cucumber.R` file:

```r
#' tests/testthat/test-cucumber.R
cucumber::test(".", "./steps")
```

It will report the results with the rest of you `testthat` tests:

```r
v | F W  S  OK | Context
v |          2 | Feature: Guess the word
== Results ================================================
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 2 ]
```



or run tests separaterly with:

```r
cucumber::test("tests/testthat/", "tests/testthat/steps")
```

## How it works

The `.feature` files are parsed and matched against step definitions.

Step functions are defined using:
- `description`: a [cucumber expression](https://github.com/cucumber/cucumber-expressions).
- and an implementation function. It must have the parameters that will be matched in the description and a `context` parameter - an environment for managing state between steps.

If a step parsed from one of `.feature` files is not found, an error will be thrown.

### Parameter types

Step implementations receive data from the `.feature` files as parameters. The values are detected via regular expressions and casted with a transformer function.

The following parameter types are available by default:

| Parameter Type |   Underlying regular expression   |                                     Description                                     |
| -------------- | --------------------------------- | ----------------------------------------------------------------------------------- |
| `{int}`        | `[+-]?(?<![.])[:digit:]+(?![.])`  | Matches integers, for example `71` or `-19`. Converts value with `as.integer`.      |
| `{float}`      | `[+-]?[[:digit:]+]?\\.[:digit:]+` | Matches floats, for example `3.6`, `.8` or `-9.2`. Converts value with `as.double`. |
| `{string}`     | `[:print:]+`                      | Matches letters, numbers, punctuation and whitespace.                               |

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
- [ ] Background
- [ ] Scenario Outline (or Scenario Template)
- [ ] Examples (or Scenarios)
- [x] `"""` (Doc Strings)
- [x] `|` (Data Tables)
- [ ] `@` (Tags)
- [x] `#` (Comments)

The goal is to support all listed features.

See the [Gherkin Reference](https://cucumber.io/docs/gherkin/reference/) on how to write Gherkin documents.

## Installation

You can install the development version of cucumber from [GitHub](https://github.com/) with:

``` r
devtools::install_github("jakubsob/cucumber")
```

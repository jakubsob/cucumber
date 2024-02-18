
# cucumber

<!-- badges: start -->
[![R-CMD-check](https://github.com/jakubsob/cucumber/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/jakubsob/cucumber/actions/workflows/R-CMD-check.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![Codecov test coverage](https://codecov.io/gh/jakubsob/cucumber/branch/main/graph/badge.svg)](https://app.codecov.io/gh/jakubsob/cucumber?branch=main)
<!-- badges: end -->

An implementation of the [Cucumber](https://cucumber.io/) testing framework in R. Fully native, no external dependencies.

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
  context
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

and running them with:

```r
cucumber::cucumber()
```

By default this command will look for Feature files in `tests/testthat` directory and step definitions in `tests/testthat/steps` directory. You can change these defaults by providing `feature_path` and `steps_path` arguments to `cucumber()` function.


## Installation

You can install the development version of cucumber from [GitHub](https://github.com/) with:

``` r
devtools::install_github("jakubsob/cucumber")
```

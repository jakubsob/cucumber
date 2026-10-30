# cucumber

Write specifications in plain-language
[Gherkin](https://cucumber.io/docs/gherkin/reference/), run them from R
as testthat tests, and read the results in the console or in Cucumber’s
own HTML report. An R implementation of the
[Cucumber](https://cucumber.io/) testing framework.

## Installation

``` r

install.packages("cucumber")
```

## Where to start

- **New to cucumber?** [Get
  started](https://jakubsob.github.io/cucumber/articles/get-started.html):
  write and run your first feature.
- **New to BDD?** Read [Behavior-Driven
  Development](https://jakubsob.github.io/cucumber/articles/bdd.html).
- **Know testthat?** See [cucumber and
  testthat](https://jakubsob.github.io/cucumber/articles/testthat.html).
- **Looking something up?** Open the [function
  reference](https://jakubsob.github.io/cucumber/reference/) or the
  [Gherkin
  reference](https://jakubsob.github.io/cucumber/articles/reference-gherkin.html).

## Run your first feature

A feature file describes behavior in Gherkin

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

and step definitions run each step in R

``` r

when("I add {float} and {float}", function(x, y, context) {
  context$result <- x + y
})

then("the result is {float}", function(expected, context) {
  expect_equal(context$result, expected)
})
```

Each Feature is a testthat context and each Scenario a
[`testthat::test_that()`](https://testthat.r-lib.org/reference/test_that.html)
case, so you get feedback on each Scenario separately. Run them with
[`cucumber::test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md):

``` r

withr::with_dir(pass_dir, {
  cucumber::test(filter = "addition")
})
```

``` R
  |  F  P  U  S  OK | Feature
v |               3 | Addition

--------------------------------------------------------------------------------
Summary
  3 scenarios (3 passed)
  6 steps (6 passed)
  0m00.100s (executing steps: 0m00.100s)
--------------------------------------------------------------------------------
```

When a step fails, the reporter shows which step broke and why, and
where its definition is. [Get
started](https://jakubsob.github.io/cucumber/articles/get-started.html)
walks through a failure, the other console reporters and where to put
the files.

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

and put them in its help page with
[`features_rd()`](https://jakubsob.github.io/cucumber/dev/reference/features_rd.md):

``` r

#' Add items to a basket
#' @eval cucumber::features_rd(features = "basket.feature")
#' @export
add <- function(basket, n) basket + n
```

`devtools::document()` adds a Behavior section to `?add` with the
feature’s description and the tagged scenarios:

``` R
Add items to a basket

Description:

     Add items to a basket

Usage:

     add(basket, n)
     
Behavior:

     Feature: Basket
       A basket holds the items a customer wants to buy.
     
       Scenario: Add an item
         Given an empty basket
         When I add 1 item
         Then the basket has 1 item
     
     Source: 'tests/acceptance/basket.feature'
```

The help pages of this package are written this way, see
[`?hook`](https://jakubsob.github.io/cucumber/reference/hook.html) or
[`?test`](https://jakubsob.github.io/cucumber/reference/test.html): the
scenarios that test cucumber explain it, and stay true because they run.

How steps are matched, and the parameter types you can use, are in [How
it
works](https://jakubsob.github.io/cucumber/articles/how-it-works.html).

# Get started

In a few minutes you’ll have a feature file written in plain language,
steps in R that check it, and a run that tells you which scenarios pass.
New to the idea behind it? Read
[`vignette("bdd")`](https://jakubsob.github.io/cucumber/dev/articles/bdd.md)
first, or come back to it later.

## Install

``` r

install.packages("cucumber")
```

cucumber runs on testthat, so you need it too:
`install.packages("testthat")`.

## Write a feature

A feature file describes behavior in
[Gherkin](https://cucumber.io/docs/gherkin/reference/), one example per
scenario. Each step is a line that starts with `Given`, `When` or
`Then`. Save this as `tests/acceptance/addition.feature`:

``` feature
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

Nothing in it says how to add numbers. That’s the point: the feature
reads the same to someone who doesn’t write R.

## Write the steps

A step definition connects a step’s text to R code. Save this as
`tests/acceptance/setup-steps-addition.R`:

``` r

when("I add {float} and {float}", function(x, y, context) {
  context$result <- x + y
})

then("the result is {float}", function(expected, context) {
  expect_equal(context$result, expected)
})
```

- `"I add {float} and {float}"` matches the text of a step. Each
  placeholder takes a number out of the text and passes it to the
  function, as `x` and `y`.
- `context` is an environment the steps of one scenario share. The
  `when` step stores the result in it and the `then` step reads it.
- `expect_equal()` is the testthat expectation you already know.

## Run it

[`cucumber::test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md)
runs the feature files of `tests/acceptance`:

``` console-output
  |  F  P  U  S  OK | Feature
✔ |               3 | Addition

────────────────────────────────────────────────────────────────────────────────
Summary
  3 scenarios (3 passed)
  6 steps (6 passed)
  0m00.067s (executing steps: 0m00.009s)
────────────────────────────────────────────────────────────────────────────────
```

One line per feature, with its scenarios counted by status. All three
scenarios passed.

## See a failure

Change the expected result in a `Then` step, say to `5`, and run again.
The reporter shows the step that failed, in which scenario, where its
definition is, and how the values differ:

``` console-output
  |  F  P  U  S  OK | Feature

Feature: Addition
  Scenario: Adding 2 integers
    ✔ When I add 1 and 1
    ✖ Then the result is 5
    Error:
      Step "the result is 5" failed
      ℹ Feature: addition.feature:4
      ℹ Scenario: Adding 2 integers
      ℹ Step defined at: setup-steps-addition.R:5
      Expected `context$result` to equal `expected`.
      Differences:
      1/1 mismatches
      [1] 2 - 5 == -3
✖ |  1            2 | Addition

Failures:

1) Scenario: Adding 2 integers # addition.feature:2
    ✔ When I add 1 and 1
    ✖ Then the result is 5
    Error:
      Step "the result is 5" failed
      ℹ Feature: addition.feature:4
      ℹ Scenario: Adding 2 integers
      ℹ Step defined at: setup-steps-addition.R:5
      Expected `context$result` to equal `expected`.
      Differences:
      1/1 mismatches
      [1] 2 - 5 == -3

────────────────────────────────────────────────────────────────────────────────
Summary
  3 scenarios (1 failed, 2 passed)
  6 steps (1 failed, 5 passed)
  0m00.060s (executing steps: 0m00.028s)
────────────────────────────────────────────────────────────────────────────────
Error: Test failures. 
```

## See every step

`CucumberPrettyReporter` prints each step as it runs, in color in a
terminal:

``` console-output
Feature: Addition
  Scenario: Adding 2 integers
    ✔ When I add 1 and 1
    ✔ Then the result is 2
  Scenario: Adding integer and float
    ✔ When I add 1 and 1.1
    ✔ Then the result is 2.1
  Scenario: Adding float and float
    ✔ When I add 1.1 and 1.1
    ✔ Then the result is 2.2


────────────────────────────────────────────────────────────────────────────────
Summary
  3 scenarios (3 passed)
  6 steps (6 passed)
  0m00.050s (executing steps: 0m00.010s)
────────────────────────────────────────────────────────────────────────────────
```

`CucumberDotsReporter`, `CucumberProgressBarReporter` and
`CucumberSummaryReporter` are the other console reporters. See the
[reference](https://jakubsob.github.io/cucumber/dev/reference/index.html#reporters).

## Where the files go

Keep acceptance tests apart from your unit tests:

``` text
tests/
├── acceptance/
│   ├── setup-steps_1.R
│   ├── setup-steps_2.R
│   ├── feature_1.feature
│   └── feature_2.feature
└── testthat/
    └── test-unit_test_1.R
```

or alongside them, and run the features from a testthat file with
[`cucumber::run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md):

``` text
tests/
└── testthat/
    ├── test-cucumber.R
    ├── test-unit_test_1.R
    ├── setup-steps_1.R
    └── feature_1.feature
```

[`vignette("testthat")`](https://jakubsob.github.io/cucumber/dev/articles/testthat.md)
explains how the two ways differ.

## Next

- [`vignette("how-it-works")`](https://jakubsob.github.io/cucumber/dev/articles/how-it-works.md):
  how steps are matched, parameter types, hooks and state.
- [`vignette("reference-gherkin")`](https://jakubsob.github.io/cucumber/dev/articles/reference-gherkin.md):
  every Gherkin keyword, with examples.
- [`vignette("reporting")`](https://jakubsob.github.io/cucumber/dev/articles/reporting.md):
  HTML and JUnit reports, with screenshots and logs.
- The
  [examples](https://github.com/jakubsob/cucumber/tree/main/inst/examples)
  directory has runnable projects.

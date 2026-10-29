# How it works

[`cucumber::test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md)
runs the `.feature` and `.feature.md` files of a directory,
`tests/acceptance` by default, and its subdirectories. A run goes like
this:

1.  **Load the step definitions.** The `helper-*.R` and `setup-*.R`
    files of the directory are run, like
    [`testthat::test_dir()`](https://testthat.r-lib.org/reference/test_dir.html)
    runs them. Calls to
    [`given()`](https://jakubsob.github.io/cucumber/dev/reference/step.md),
    [`when()`](https://jakubsob.github.io/cucumber/dev/reference/step.md),
    [`then()`](https://jakubsob.github.io/cucumber/dev/reference/step.md),
    the hooks and
    [`define_parameter_type()`](https://jakubsob.github.io/cucumber/dev/reference/define_parameter_type.md)
    in them register step definitions, hooks and parameter types for the
    run.
2.  **Parse the feature files.** Every feature file is parsed before
    anything runs. If one can’t be parsed, no scenario runs, and every
    parse error is reported with its file, line and column.
3.  **Compile the scenarios.** Each scenario, and each row of a Scenario
    Outline’s Examples, becomes one test case, with the `Background`
    steps before its own steps.
4.  **Select and order them**, by `filter`, `name`, `tags` and
    `features`, and by `order`.
5.  **Run them.** Each step is matched to a step definition, and the
    step definitions are called one by one.
6.  **Report them.** Every outcome of the run is a [Cucumber
    Message](https://github.com/cucumber/messages), passed to the
    reporter: the progress in the console, or reports like the HTML
    report, see
    [`vignette("reporting")`](https://jakubsob.github.io/cucumber/dev/articles/reporting.md).

[`run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md) does
the same in a testthat test file, where testthat reports each scenario
as a test. See
[`vignette("testthat")`](https://jakubsob.github.io/cucumber/dev/articles/testthat.md)
for how cucumber and testthat compare.

## Step execution order

Given such a feature file:

``` gherkin
# tests/acceptance/sum.feature
Feature: Sum
  Scenario: Sum should work for 2 numbers
    Given I have 1
    And I have 2
    When I add them
    Then I get 3

  Scenario: Sum should work for 3 numbers
    Given I have 1
    And I have 2
    But I have 3
    When I add them
    Then I get 6
```

And such step definitions:

``` r

# tests/acceptance/setup-steps.R
given("I have {int}", function(int, context) {
  print("given")
  context$numbers <- c(context$numbers, int)
})

when("I add them", function(context) {
  print("when")
  context$result <- sum(context$numbers)
})

then("I get {int}", function(int, context) {
  print("then")
  expect_equal(context$result, int)
})
```

The order of calling the steps would be:

``` r

#> [1] "given"
#> [1] "given"
#> [1] "when"
#> [1] "then"
#> [1] "given"
#> [1] "given"
#> [1] "given"
#> [1] "when"
#> [1] "then"
```

Hooks run around them:
[`before_all()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
once before the first scenario,
[`before()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
and
[`after()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
around each scenario,
[`before_step()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
and
[`after_step()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
around each step, and
[`after_all()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
once after the last scenario. See
[`?hook`](https://jakubsob.github.io/cucumber/dev/reference/hook.md).

## Sharing state with `context`

Each scenario gets a new, empty `context` environment, shared by its
steps and hooks. State doesn’t leak from one scenario to the next.

Code a step or a hook defers in `context`, like
`withr::local_options(.local_envir = context)`, runs when the scenario
ends.

## Matching steps

A step is matched to a step definition by its text, without its keyword:
`Given I have 1` and `And I have 1` match the same definition.

A step definition’s description is a [Cucumber
Expression](https://github.com/cucumber/cucumber-expressions), like
`"I have {int}"`, or a regular expression if it starts with `^`, ends
with `$` or is surrounded by `/`. The values its parameters match are
passed to the step definition, before its Data Table or Doc String and
`context`. See
[`?step`](https://jakubsob.github.io/cucumber/dev/reference/step.md) and
[`?define_parameter_type`](https://jakubsob.github.io/cucumber/dev/reference/define_parameter_type.md).

Every step gets a result:

- **passed**: its step definition ran without an error or a failed
  expectation.
- **failed**: its step definition failed. The steps after it are
  **skipped**.
- **pending**: its step definition called
  [`pending()`](https://jakubsob.github.io/cucumber/dev/reference/pending.md).
- **undefined**: no step definition matches it. The run goes on with the
  next scenario, and shows a snippet of a step definition to paste into
  a setup file.
- **ambiguous**: more than one step definition matches it. The error
  lists them all.

A scenario with a pending or undefined step fails, unless the run is
given `strict = FALSE`. `cucumber::test(dry_run = TRUE)` finds every
undefined and ambiguous step without running any.

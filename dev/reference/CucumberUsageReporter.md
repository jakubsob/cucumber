# Cucumber Usage Reporter

Prints how each step definition was used when the run ends, like
Cucumber's `usage` formatter: its expression, the mean duration of its
steps and where it's defined, then the steps it matched, the slowest
first. A step definition no step matched is `UNUSED`. Use it to find
slow steps and step definitions to remove. To also see the progress of
the run, combine it with another reporter in a
[CucumberMultiReporter](https://jakubsob.github.io/cucumber/dev/reference/CucumberMultiReporter.md).

    Step definition / Step         Duration  Location
    I add {int} apples             1.52ms    setup-steps.R:3
      I add 2 apples               2.01ms    basket.feature:4
      I add 1 apples               1.03ms    basket.feature:9
    I remove {int} apples          UNUSED    setup-steps.R:6

## Behavior

```
```

### Feature: Usage reporter

`CucumberUsageReporter` prints how each step definition was used when
the run ends, like Cucumber's `usage` formatter. Each step definition is
listed with the mean duration of its steps and where it's defined,
followed by the steps it matched, the slowest first, with where they
are. A step definition that no step matched is `UNUSED`. It finds slow
steps, and step definitions to remove.

#### Background:

- Given a package

- And a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add apples
      Given an empty basket
      When I add 2 apples
      And I add 1 apples

    Scenario: Wait
      Given an empty basket
      When I wait
  ```

- And a file named "features/setup-steps.R" with

      given("an empty basket", function(context) {})
      when("I add {int} apples", function(n, context) {})
      when("I wait", function(context) Sys.sleep(0.1))
      when("I remove {int} apples", function(n, context) {})

#### Scenario: Each step definition is listed with the steps it matched

A dry run doesn't run the steps, so they have no duration.

- When I run

      test("features", dry_run = TRUE, reporter = CucumberUsageReporter$new())

- Then the output includes

      Step definition / Step  Duration  Location
      an empty basket         -         setup-steps.R:1
        an empty basket       -         basket.feature:3
        an empty basket       -         basket.feature:8
      I add {int} apples      -         setup-steps.R:2
        I add 2 apples        -         basket.feature:4
        I add 1 apples        -         basket.feature:5
      I wait                  -         setup-steps.R:3
        I wait                -         basket.feature:9
      I remove {int} apples   UNUSED    setup-steps.R:4

#### Scenario: A regular expression is shown between slashes

- Given a file named "features/setup-steps.R" with

      given("an empty basket", function(context) {})
      when("^I add (\\d+) apples$", function(n, context) {})
      when("I wait", function(context) {})

- When I run

      test("features", dry_run = TRUE, reporter = CucumberUsageReporter$new())

- Then the output includes

      Step definition / Step  Duration  Location
      an empty basket         -         setup-steps.R:1
        an empty basket       -         basket.feature:3
        an empty basket       -         basket.feature:8
      /^I add (\d+) apples$/  -         setup-steps.R:2
        I add 2 apples        -         basket.feature:4
        I add 1 apples        -         basket.feature:5
      I wait                  -         setup-steps.R:3
        I wait                -         basket.feature:9

#### Scenario: A run without step definitions has no usage to show

- Given a file named "features/setup-steps.R" with

- When I run

      test("features", dry_run = TRUE, reporter = CucumberUsageReporter$new())

- Then the output includes "No step definitions"

#### Scenario: The slowest step definitions come first, and the unused ones last

- When I run

      test("features", reporter = CucumberUsageReporter$new())

- Then the output includes lines matching these patterns in order:

      ^I wait +[0-9.]+ms +setup-steps.R:3$
      ^I wait +[0-9.]+ms +basket.feature:9$
      ^I remove \{int\} apples +UNUSED +setup-steps.R:4$

#### Scenario: Only the five slowest steps of a step definition are listed

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add apples
      When I add 1 apples
      And I add 2 apples
      And I add 3 apples
      And I add 4 apples
      And I add 5 apples
      And I add 6 apples
      And I add 7 apples
  ```

- When I run

      test("features", dry_run = TRUE, reporter = CucumberUsageReporter$new())

- Then the output includes

      I add {int} apples      -         setup-steps.R:2
        I add 1 apples        -         basket.feature:3
        I add 2 apples        -         basket.feature:4
        I add 3 apples        -         basket.feature:5
        I add 4 apples        -         basket.feature:6
        I add 5 apples        -         basket.feature:7
        ... 2 more

#### Scenario: An ambiguous step isn't a use of its step definitions

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add apples
      When I add 2 apples
  ```

- And a file named "features/setup-steps.R" with

      when("I add {int} apples", function(n, context) {})
      when("I add {float} apples", function(n, context) {})

- When I run

      test("features", dry_run = TRUE, reporter = CucumberUsageReporter$new())

- Then the output includes

      I add {int} apples      UNUSED    setup-steps.R:1
      I add {float} apples    UNUSED    setup-steps.R:2

Source: `tests/acceptance/r-usage_reporter.feature`

## Super classes

[`cucumber::CucumberReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.md)
-\>
[`cucumber::CucumberQueryReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberQueryReporter.md)
-\> `CucumberUsageReporter`

## Methods

### Public methods

- [`CucumberUsageReporter$new()`](#method-CucumberUsageReporter-new)

- [`CucumberUsageReporter$end_run()`](#method-CucumberUsageReporter-end_run)

- [`CucumberUsageReporter$clone()`](#method-CucumberUsageReporter-clone)

Inherited methods

- [`cucumber::CucumberReporter$add_warning()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.html#method-add_warning)
- [`cucumber::CucumberReporter$report()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.html#method-report)
- [`cucumber::CucumberQueryReporter$add_message()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberQueryReporter.html#method-add_message)
- [`cucumber::CucumberQueryReporter$start_run()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberQueryReporter.html#method-start_run)

------------------------------------------------------------------------

### Method `new()`

Create a usage reporter

#### Usage

    CucumberUsageReporter$new(file = NULL)

#### Arguments

- `file`:

  Path of a file to print to instead of the console, replaced by each
  run, or `NULL`. A relative path is relative to the working directory
  when the reporter is created. Its directory is created when the
  reporter is, if it doesn't exist.

------------------------------------------------------------------------

### Method `end_run()`

Print the usage of the step definitions

#### Usage

    CucumberUsageReporter$end_run(error = NULL)

#### Arguments

- `error`:

  The error that stopped the run, or `NULL`

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    CucumberUsageReporter$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
cucumber::test(reporter = cucumber::CucumberUsageReporter$new())
} # }
```

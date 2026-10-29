# Cucumber Snippets Reporter

Prints only the snippets of the step definitions that undefined steps
need, like Cucumber's `snippets` formatter, to paste them into a setup
file. A step undefined in several scenarios gets one snippet.

    when("I add {int} cucumbers", function(int, context) {
    # when("I add {float} cucumbers", function(float, context) {
      pending()
    })

## Behavior

```
```

### Feature: Snippets reporter

`CucumberSnippetsReporter` prints only the snippets of the step
definitions that undefined steps need, like Cucumber's `snippets`
formatter, to paste them into a setup file. A step undefined in several
scenarios gets one snippet.

#### Background:

- Given a package

- And a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add cucumbers
      Given an empty basket
      When I add 5 cucumbers
      Then the basket is full

    Scenario: Empty the basket
      Given an empty basket
      When I empty the basket
  ```

- And a file named "features/setup-steps.R" with

      given("an empty basket", function(context) {})

#### Scenario: Only the snippets of undefined steps are printed

- When I run

      test("features", reporter = CucumberSnippetsReporter$new(), stop_on_failure = FALSE)

- Then the output includes

      when("I add {int} cucumbers", function(int, context) {
      # when("I add {float} cucumbers", function(float, context) {
      pending()
      })then("the basket is full", function(context) {
      pending()
      })when("I empty the basket", function(context) {
      pending()
      })

- And the output doesn't include "Scenario"

- And the output doesn't include "an empty basket"

#### Scenario: A step undefined in several scenarios gets one snippet

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add cucumbers
      Given a full basket

    Scenario: Empty the basket
      Given a full basket
  ```

- When I run

      test("features", reporter = CucumberSnippetsReporter$new(), stop_on_failure = FALSE)

- Then the output includes 'given("a full basket", function(context) {'
  1 time

#### Scenario: A run without undefined steps prints nothing

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Start shopping
      Given an empty basket
  ```

- When I run

      test("features", reporter = CucumberSnippetsReporter$new())

- Then the output is empty

Source: `tests/acceptance/r-snippets_reporter.feature`

## Super class

[`cucumber::CucumberReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.md)
-\> `CucumberSnippetsReporter`

## Methods

### Public methods

- [`CucumberSnippetsReporter$new()`](#method-CucumberSnippetsReporter-new)

- [`CucumberSnippetsReporter$start_run()`](#method-CucumberSnippetsReporter-start_run)

- [`CucumberSnippetsReporter$add_message()`](#method-CucumberSnippetsReporter-add_message)

- [`CucumberSnippetsReporter$end_run()`](#method-CucumberSnippetsReporter-end_run)

- [`CucumberSnippetsReporter$clone()`](#method-CucumberSnippetsReporter-clone)

Inherited methods

- [`cucumber::CucumberReporter$add_warning()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.html#method-add_warning)
- [`cucumber::CucumberReporter$report()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.html#method-report)

------------------------------------------------------------------------

### Method `new()`

Create a snippets reporter

#### Usage

    CucumberSnippetsReporter$new(file = NULL)

#### Arguments

- `file`:

  Path of a file to print to instead of the console, replaced by each
  run, or `NULL`. A relative path is relative to the working directory
  when the reporter is created. Its directory is created when the
  reporter is, if it doesn't exist.

------------------------------------------------------------------------

### Method `start_run()`

Start collecting the snippets of a run

#### Usage

    CucumberSnippetsReporter$start_run()

------------------------------------------------------------------------

### Method `add_message()`

Collect the snippets of an undefined step

#### Usage

    CucumberSnippetsReporter$add_message(envelope)

#### Arguments

- `envelope`:

  A list with one element, named by the message's type

------------------------------------------------------------------------

### Method `end_run()`

Print the snippets

#### Usage

    CucumberSnippetsReporter$end_run(error = NULL)

#### Arguments

- `error`:

  The error that stopped the run, or `NULL`

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    CucumberSnippetsReporter$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
cucumber::test(reporter = cucumber::CucumberSnippetsReporter$new())
} # }
```

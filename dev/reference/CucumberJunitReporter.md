# Cucumber JUnit Reporter

Writes the run as a JUnit XML report, the one of the official Cucumber
JUnit XML formatter (<https://github.com/cucumber/junit-xml-formatter>),
for CI services like Jenkins, GitHub Actions or GitLab. To also see the
progress of the run, combine it with another reporter in a
[CucumberMultiReporter](https://jakubsob.github.io/cucumber/dev/reference/CucumberMultiReporter.md).
To write the report of a run after it ran, store its messages with
[CucumberMessagesReporter](https://jakubsob.github.io/cucumber/dev/reference/CucumberMessagesReporter.md)
and pass their file to the `$report()` method.

## Behavior

```
```

### Feature: JUnit reporter

`CucumberJunitReporter` writes the JUnit XML report of a run when the
run ends, even when it fails. CI services read it to show the results of
the run.

Each scenario is a test case, each example of an outline being one. Its
class name is the feature's name and its name is the scenario's, after
the rule's, followed by the name and number of the example, and the
example's own name when the outline's name has placeholders. A scenario
that passed, failed or was skipped is a passed, failed or skipped test
case. A pending, undefined or ambiguous scenario is a failed one. Its
steps and their results are the test case's output. A
[`before_all()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
or
[`after_all()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
hook that failed is a failed test case too, named after where it's
defined.

#### Background:

- Given a package

#### Scenario: Each scenario is a test case, with its result

A pending, undefined or ambiguous scenario is a failed test case.

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket

    Scenario: Remove an item
      Given an empty basket
      When I remove an item

    Scenario: Pay
      Given an empty basket
      When I pay

    Scenario: Skip
      Given the basket isn't ready

    Scenario: Undefined
      When I empty the basket

    Scenario: Ambiguous
      When I check the basket

    Rule: Items are counted
      Scenario Outline: Add <n> items
        When I add <n> items

        Examples: Few
          | n |
          | 1 |
          | 2 |
  ```

- And a file named "features/setup-steps.R" with

      given("an empty basket", function(context) {})
      when("I remove an item", function(context) stop("The basket is empty"))
      when("I pay", function(context) pending())
      given("the basket isn't ready", function(context) skip_scenario("Not ready"))
      when("I add {int} items", function(n, context) {})
      when("I check the basket", function(context) {})
      when("I check the {word}", function(thing, context) {})

- When I run

      test("features", reporter = CucumberJunitReporter$new("report.xml"), stop_on_failure = FALSE)

- Then the JUnit report "report.xml" has these test cases:

  |  |  |  |  |
  |----|----|----|----|
  | classname | name | result | message |
  | Basket | Add an item | passed |  |
  | Basket | Remove an item | failure | The basket is empty |
  | Basket | Pay | failure | Step "I pay" is pending: TODO |
  | Basket | Skip | skipped |  |
  | Basket | Undefined | failure |  |
  | Basket | Ambiguous | failure |  |
  | Basket | Items are counted - Add \<n\> items - Few - \#1.1: Add 1 items | passed |  |
  | Basket | Items are counted - Add \<n\> items - Few - \#1.2: Add 2 items | passed |  |

#### Scenario: A failed before_all() or after_all() hook is a failed test case

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket
  ```

- And a file named "features/setup-steps.R" with

      before_all(function() {})
      after_all(function() stop("The server didn't stop"))
      given("an empty basket", function(context) {})

- When I run

      test("features", reporter = CucumberJunitReporter$new("report.xml"), stop_on_failure = FALSE)

- Then the JUnit report "report.xml" has these test cases:

  |                 |         |                        |
  |-----------------|---------|------------------------|
  | name            | result  | message                |
  | setup-steps.R:2 | failure | The server didn't stop |
  | Add an item     | passed  |                        |

#### Scenario: A test case's output is its steps and their results

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Remove an item
      Given an empty basket
      When I remove an item
      Then the basket is empty
  ```

- And a file named "features/setup-steps.R" with

      given("an empty basket", function(context) {})
      when("I remove an item", function(context) stop("The basket is empty"))
      then("the basket is empty", function(context) {})

- When I run

      test("features", reporter = CucumberJunitReporter$new("report.xml"), stop_on_failure = FALSE)

- Then the output of the test case "Remove an item" in the JUnit report
  "report.xml" is

      Given an empty basket.......................................................passed
      When I remove an item.......................................................failed
      Then the basket is empty....................................................skipped

#### Scenario: An error with characters XML doesn't allow is written as the message of the failure

An error can have characters XML doesn't allow, like the escape
character of the colors of a terminal. Each is written as the text of
its character reference, like `&#27;`, so the report is still XML that
CI services read.

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Remove an item
      When I remove an item
  ```

- And a file named "features/setup-steps.R" with

      when("I remove an item", function(context) stop("The basket is \033[31mempty\033[39m"))

- When I run

      test("features", reporter = CucumberJunitReporter$new("report.xml"), stop_on_failure = FALSE)

- Then the JUnit report "report.xml" has these test cases:

  |                |         |                                         |
  |----------------|---------|-----------------------------------------|
  | name           | result  | message                                 |
  | Remove an item | failure | The basket is &#27;\[31mempty&#27;\[39m |

#### Scenario: The report is written to cucumber-junit.xml by default

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket
  ```

- And a file named "features/setup-steps.R" with

      given("an empty basket", function(context) {})

- When I run

      test("features", reporter = CucumberJunitReporter$new())

- Then the JUnit report "cucumber-junit.xml" has these test cases:

  |             |        |
  |-------------|--------|
  | name        | result |
  | Add an item | passed |

Source: `tests/acceptance/r-junit_reporter.feature`

## Super classes

[`cucumber::CucumberReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.md)
-\>
[`cucumber::CucumberQueryReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberQueryReporter.md)
-\> `CucumberJunitReporter`

## Public fields

- `file`:

  Path of the XML file the report is written to

## Methods

### Public methods

- [`CucumberJunitReporter$new()`](#method-CucumberJunitReporter-new)

- [`CucumberJunitReporter$end_run()`](#method-CucumberJunitReporter-end_run)

- [`CucumberJunitReporter$clone()`](#method-CucumberJunitReporter-clone)

Inherited methods

- [`cucumber::CucumberReporter$add_warning()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.html#method-add_warning)
- [`cucumber::CucumberReporter$report()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.html#method-report)
- [`cucumber::CucumberQueryReporter$add_message()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberQueryReporter.html#method-add_message)
- [`cucumber::CucumberQueryReporter$start_run()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberQueryReporter.html#method-start_run)

------------------------------------------------------------------------

### Method `new()`

Create a JUnit reporter

#### Usage

    CucumberJunitReporter$new(file = "cucumber-junit.xml")

#### Arguments

- `file`:

  Path of the XML file to write, replaced by each run. A relative path
  is relative to the working directory when the reporter is created. Its
  directory is created when the reporter is, if it doesn't exist.

------------------------------------------------------------------------

### Method `end_run()`

Write the report

#### Usage

    CucumberJunitReporter$end_run(error = NULL)

#### Arguments

- `error`:

  The error that stopped the run, or `NULL`

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    CucumberJunitReporter$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
cucumber::test(reporter = cucumber::CucumberJunitReporter$new("cucumber-junit.xml"))

# With the progress of the run
cucumber::test(reporter = cucumber::CucumberMultiReporter$new(list(
  cucumber::CucumberProgressReporter$new(),
  cucumber::CucumberJunitReporter$new("cucumber-junit.xml")
)))

# From the messages of a run, after it ran
cucumber::test(reporter = cucumber::CucumberMessagesReporter$new("cucumber.ndjson"))
cucumber::CucumberJunitReporter$new("cucumber-junit.xml")$report("cucumber.ndjson")
} # }
```

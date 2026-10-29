# Cucumber Messages Reporter

Writes the run as [Cucumber
Messages](https://github.com/cucumber/messages). To also see the
progress of the run, combine it with another reporter in a
[CucumberMultiReporter](https://jakubsob.github.io/cucumber/dev/reference/CucumberMultiReporter.md).

The messages follow the protocol version 34.2.1 and are checked with the
Cucumber Compatibility Kit. Locations of step definitions and hooks need
their source references, kept when the files are sourced with
`keep.source = TRUE`, as testthat does.

## Behavior

```
```

### Feature: Messages reporter

`CucumberMessagesReporter` writes a run as Cucumber Messages, one JSON
message per line (NDJSON), like the `message` formatter of other
Cucumber implementations. Official tools read it, like the HTML, JUnit
and JSON formatters.

#### Background:

- Given a package

- And a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket
      When I add 2 apples
      Then the basket has 2 items
  ```

- And a file named "features/setup-steps.R" with

      before(function(context, scenario) context$items <- 0)
      given("an empty basket", function(context) {})
      when("I add {int} apples", function(int, context) context$items <- context$items + int)
      then("the basket has {int} items", function(int, context) expect_equal(context$items, int))

#### Scenario: The run is written as messages

- When I run

      test("features", reporter = CucumberMessagesReporter$new("messages.ndjson"))
      messages <- lapply(readLines("messages.ndjson"), jsonlite::fromJSON)
      cat(vapply(messages, names, character(1)), sep = "\n")

- Then the output includes

      meta
      source
      gherkinDocument
      pickle
      hook
      stepDefinition
      stepDefinition
      stepDefinition
      testRunStarted
      testCase
      testCaseStarted
      testStepStarted
      testStepFinished
      testStepStarted
      testStepFinished
      testStepStarted
      testStepFinished
      testStepStarted
      testStepFinished
      testCaseFinished
      testRunFinished

#### Scenario: The messages are written to a connection

- When I run

      test("features", reporter = CucumberMessagesReporter$new(stdout()))

- Then the output includes

      {"testRunFinished":

#### Scenario: Each step's result is written as a testStepFinished message

- Given a file named "features/setup-steps.R" with

      given("an empty basket", function(context) {})
      when("I add {int} apples", function(int, context) pending())

- When I run

      test("features", reporter = CucumberMessagesReporter$new("messages.ndjson"), stop_on_failure = FALSE)
      messages <- lapply(readLines("messages.ndjson"), jsonlite::fromJSON)
      finished <- Filter(\(message) !is.null(message$testStepFinished), messages)
      cat(vapply(finished, \(message) message$testStepFinished$testStepResult$status, character(1)), sep = "\n")

- Then the output includes

      PASSED
      PENDING
      UNDEFINED

#### Scenario: The run is written as messages and its progress is printed

- When I run

      test("features", reporter = CucumberMultiReporter$new(list(
        CucumberPrettyReporter$new(),
        CucumberMessagesReporter$new("messages.ndjson")
      )))
      cat(nrow(read_messages("messages.ndjson")$scenarios), "scenario written\n")

- Then the output includes

      Scenario: Add an item
      v Given an empty basket
      v When I add 2 apples
      v Then the basket has 2 items

- And the output includes "1 scenario written"

#### Scenario: A failed step's error has the backtrace of the step as its stack trace

- Given a file named "features/setup-steps.R" with

      open_basket <- function() find_basket()
      find_basket <- function() stop("basket is missing")
      given("an empty basket", function(context) open_basket())

- When I run

      test("features", reporter = CucumberMessagesReporter$new("messages.ndjson"), stop_on_failure = FALSE)
      messages <- lapply(readLines("messages.ndjson"), jsonlite::fromJSON)
      finished <- Filter(\(message) !is.null(message$testStepFinished$testStepResult$exception), messages)
      cat(finished[[1]]$testStepFinished$testStepResult$exception$stackTrace)

- Then the output includes lines matching these patterns in order:

      open_basket\(\)
      find_basket\(\)

Source: `tests/acceptance/r-messages_reporter.feature`

## Super class

[`cucumber::CucumberReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.md)
-\> `CucumberMessagesReporter`

## Public fields

- `file`:

  Path or connection the messages are written to

## Methods

### Public methods

- [`CucumberMessagesReporter$new()`](#method-CucumberMessagesReporter-new)

- [`CucumberMessagesReporter$add_message()`](#method-CucumberMessagesReporter-add_message)

- [`CucumberMessagesReporter$clone()`](#method-CucumberMessagesReporter-clone)

Inherited methods

- [`cucumber::CucumberReporter$add_warning()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.html#method-add_warning)
- [`cucumber::CucumberReporter$end_run()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.html#method-end_run)
- [`cucumber::CucumberReporter$report()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.html#method-report)
- [`cucumber::CucumberReporter$start_run()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.html#method-start_run)

------------------------------------------------------------------------

### Method `new()`

Create a messages reporter

#### Usage

    CucumberMessagesReporter$new(file = "cucumber.ndjson")

#### Arguments

- `file`:

  Path of the file to write, replaced by each run, or a connection, like
  [`stdout()`](https://rdrr.io/r/base/showConnections.html). A relative
  path is relative to the working directory when the reporter is
  created. Its directory is created when the reporter is, if it doesn't
  exist.

------------------------------------------------------------------------

### Method `add_message()`

Write a message as a line of JSON

#### Usage

    CucumberMessagesReporter$add_message(envelope)

#### Arguments

- `envelope`:

  A list with one element, named by the message's type

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    CucumberMessagesReporter$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
cucumber::test(reporter = cucumber::CucumberMessagesReporter$new("cucumber.ndjson"))

# With the progress of the run
cucumber::test(reporter = cucumber::CucumberMultiReporter$new(list(
  cucumber::CucumberProgressReporter$new(),
  cucumber::CucumberMessagesReporter$new("cucumber.ndjson")
)))
} # }
```

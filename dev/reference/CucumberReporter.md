# Cucumber Reporter Base Class

Base class for cucumber reporters. Extend it to report a run your way,
overriding the methods you need. Each does nothing by default.

## Methods

- `start_run()`:

  Called when a run starts

- `end_run(error)`:

  Called when a run ends, with the error that stopped it, like a failing
  [`before_all()`](https://jakubsob.github.io/cucumber/dev/reference/hook.md)
  hook, or `NULL`

- `add_message(envelope)`:

  Called with each Cucumber Message of the run, see
  [CucumberMessagesReporter](https://jakubsob.github.io/cucumber/dev/reference/CucumberMessagesReporter.md)

- `add_warning(warning)`:

  Called with each warning raised in a step, a hook or elsewhere in the
  run

- `report(file)`:

  Reports a run after it ran, from the Cucumber Messages
  [CucumberMessagesReporter](https://jakubsob.github.io/cucumber/dev/reference/CucumberMessagesReporter.md)
  stored in `file`

An envelope is a list with one element, named by the message's type. The
messages of a scenario are, in order:

- `testCaseStarted`, with the `id` its other messages refer to and the
  `testCaseId` of its `testCase`, sent before any scenario runs, whose
  `pickleId` is the id of its `pickle`: the scenario's name, tags and
  steps.

- `testStepStarted` and `testStepFinished` of each hook and step, with
  the `testStepResult`: its `status`, like `"PASSED"`, `duration` and
  the `message` of its error.

- `testCaseFinished`.

Combine reporters with
[CucumberMultiReporter](https://jakubsob.github.io/cucumber/dev/reference/CucumberMultiReporter.md).

## Behavior

```
```

### Feature: Custom reporter

Extend `CucumberReporter` to report the run your way. A reporter gets
the start and the end of the run, each of its Cucumber Messages and the
warnings raised in it. Pass the reporter to
[`test()`](https://jakubsob.github.io/cucumber/dev/reference/test.md) or
[`run()`](https://jakubsob.github.io/cucumber/dev/reference/run.md) with
`reporter`. Only cucumber reporters can report a run, testthat reporters
can't.

#### Background:

- Given a package

- And a file named "event-reporter.R" with

      EventReporter <- R6::R6Class(
        "EventReporter",
        inherit = cucumber::CucumberReporter,
        public = list(
          start_run = function() cat("start run\n"),
          end_run = function(error) {
            cat("end run:", if (is.null(error)) "passed" else conditionMessage(error), "\n")
          },
          add_message = function(envelope) cat("message:", names(envelope), "\n"),
          add_warning = function(warning) cat("warning:", conditionMessage(warning), "\n")
        )
      )

#### Scenario: A reporter gets the run as Cucumber Messages

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket
  ```

- And a file named "features/setup-steps.R" with

      given("an empty basket", function(context) {})

- When I run

      source("event-reporter.R")
      test("features", reporter = EventReporter$new())

- Then the output includes

      start run
      message: meta
      message: source
      message: gherkinDocument
      message: pickle
      message: stepDefinition
      message: testRunStarted
      message: testCase
      message: testCaseStarted
      message: testStepStarted
      message: testStepFinished
      message: testCaseFinished
      message: testRunFinished
      end run: passed

#### Scenario: A reporter gets the warnings raised in steps and hooks

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket
  ```

- And a file named "features/setup-steps.R" with

      before(function(context, scenario) warning("the database is slow"))
      given("an empty basket", function(context) warning("the basket is dusty"))

- When I run

      source("event-reporter.R")
      test("features", reporter = EventReporter$new())

- Then the output includes

      message: testCaseStarted
      message: testStepStarted
      warning: the database is slow
      message: testStepFinished
      message: testStepStarted
      warning: the basket is dusty
      message: testStepFinished
      message: testCaseFinished

#### Scenario: A reporter gets the error that stopped the run

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket
  ```

- And a file named "features/setup-steps.R" with

      before_all(function() stop("the server didn't start"))
      given("an empty basket", function(context) {})

- When I run

      source("event-reporter.R")
      test("features", reporter = EventReporter$new(), stop_on_failure = FALSE)

- Then the output includes these lines in order:

      start run
      end run: Hook `before_all()` failed
      i Hook defined at: setup-steps.R:1
      Caused by error:
      ! the server didn't start

#### Scenario: A reporter that fails stops the run with its error

The scenarios after it don't run, and the error names the reporter and
the event it failed in.

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket

    Scenario: Remove an item
      Given an empty basket
  ```

- And a file named "features/setup-steps.R" with

      given("an empty basket", function(context) {})

- And a file named "broken-reporter.R" with

      BrokenReporter <- R6::R6Class(
        "BrokenReporter",
        inherit = EventReporter,
        public = list(
          add_message = function(envelope) {
            if (!is.null(envelope$testStepFinished)) stop("can't format the step")
            super$add_message(envelope)
          }
        )
      )

- When I run it and it fails

      source("event-reporter.R")
      source("broken-reporter.R")
      test("features", reporter = BrokenReporter$new(), stop_on_failure = FALSE)

- Then it fails with

      Error:
      ! Reporter `BrokenReporter` failed in `add_message()`.
      Caused by error:
      ! can't format the step

- And the output includes "message: testCaseStarted" once

#### Scenario: A testthat reporter can't report a run

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket
  ```

- And a file named "features/setup-steps.R" with

      given("an empty basket", function(context) {})

- When I run it and it fails

      test("features", reporter = testthat::ProgressReporter$new())

- Then it fails with

      Error:
      ! `reporter` must be a `CucumberReporter`, or `NULL` to report nothing.
      i testthat reporters can't report a cucumber run, use one of cucumber's, like `CucumberProgressReporter$new()`.

Source: `tests/acceptance/r-custom_reporter.feature`

## Public fields

- `output`:

  Path of the file what the reporter prints goes to, replaced by each
  run, or `NULL` to print to the console

## Methods

### Public methods

- [`CucumberReporter$start_run()`](#method-CucumberReporter-start_run)

- [`CucumberReporter$end_run()`](#method-CucumberReporter-end_run)

- [`CucumberReporter$add_warning()`](#method-CucumberReporter-add_warning)

- [`CucumberReporter$add_message()`](#method-CucumberReporter-add_message)

- [`CucumberReporter$report()`](#method-CucumberReporter-report)

- [`CucumberReporter$clone()`](#method-CucumberReporter-clone)

------------------------------------------------------------------------

### Method `start_run()`

Start a run

#### Usage

    CucumberReporter$start_run()

------------------------------------------------------------------------

### Method `end_run()`

End a run

#### Usage

    CucumberReporter$end_run(error = NULL)

#### Arguments

- `error`:

  The error that stopped the run, or `NULL`

------------------------------------------------------------------------

### Method `add_warning()`

Called with each warning raised in a step, a hook or elsewhere in the
run

#### Usage

    CucumberReporter$add_warning(warning)

#### Arguments

- `warning`:

  The warning

------------------------------------------------------------------------

### Method `add_message()`

Called with each Cucumber Message of the run

#### Usage

    CucumberReporter$add_message(envelope)

#### Arguments

- `envelope`:

  A list with one element, named by the message's type, like
  `list(testCaseStarted = list(...))`

------------------------------------------------------------------------

### Method `report()`

Report a run after it ran: send this reporter the Cucumber Messages
stored in a file, like a run reports them

#### Usage

    CucumberReporter$report(file)

#### Arguments

- `file`:

  Path of the NDJSON file a
  [CucumberMessagesReporter](https://jakubsob.github.io/cucumber/dev/reference/CucumberMessagesReporter.md)
  wrote

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    CucumberReporter$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Count the steps and hooks by status
StatusReporter <- R6::R6Class(
  "StatusReporter",
  inherit = cucumber::CucumberReporter,
  public = list(
    statuses = character(),
    add_message = function(envelope) {
      finished <- envelope$testStepFinished
      if (!is.null(finished)) {
        self$statuses <- c(self$statuses, finished$testStepResult$status)
      }
    },
    end_run = function(error = NULL) {
      print(table(self$statuses))
    }
  )
)
cucumber::test("tests/acceptance", reporter = StatusReporter$new())
} # }
```

# Cucumber HTML Reporter

Writes the run as the official Cucumber HTML report
(<https://github.com/cucumber/html-formatter>). To also see the progress
of the run, combine it with another reporter in a
[CucumberMultiReporter](https://jakubsob.github.io/cucumber/dev/reference/CucumberMultiReporter.md).
To write the report of a run after it ran, store its messages with
[CucumberMessagesReporter](https://jakubsob.github.io/cucumber/dev/reference/CucumberMessagesReporter.md)
and pass their file to the `$report()` method.

## Behavior

```
```

### Feature: HTML reporter

`CucumberHtmlReporter` writes the official Cucumber HTML report of a run
when the run ends, even when it fails. The page is one file, with the
report's script and styles and the messages of the run, so it works
offline. It can be searched and filtered by status, text and tags.

#### Background:

- Given a package

#### Scenario: Each step is shown with its result and the error of a step that didn't pass

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket
      When I add an item
      Then the basket has 1 item
  ```

- And a file named "features/setup-steps.R" with

      given("an empty basket", function(context) context$items <- 0)
      when("I add an item", function(context) context$items <- context$items + 1)
      then("the basket has {int} item(s)", function(int, context) expect_equal(context$items, 2))

- When I run

      test("features", reporter = CucumberHtmlReporter$new("report.html"), stop_on_failure = FALSE)

- Then the HTML report "report.html" shows these steps:

  |  |  |  |
  |----|----|----|
  | step | status | error |
  | Given an empty basket | passed |  |
  | When I add an item | passed |  |
  | Then the basket has 1 item | failed | expectation_failure Expected `context$items` to equal 2. |

#### Scenario: The report is written to cucumber-report.html by default

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      Given an empty basket
  ```

- And a file named "features/setup-steps.R" with

      given("an empty basket", function(context) context$items <- 0)

- When I run

      test("features", reporter = CucumberHtmlReporter$new())

- Then the HTML report "cucumber-report.html" shows these steps:

  |                       |        |
  |-----------------------|--------|
  | step                  | status |
  | Given an empty basket | passed |

#### Scenario: Text of the messages can't end the report's script

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add a <!--<script> to the basket
      Given an empty basket
  ```

- And a file named "features/setup-steps.R" with

      given("an empty basket", function(context) context$items <- 0)

- When I run

      test("features", reporter = CucumberHtmlReporter$new("report.html"))

- Then the HTML report "report.html" shows these steps:

  |                       |        |
  |-----------------------|--------|
  | step                  | status |
  | Given an empty basket | passed |

#### Scenario: The attachments of a step are shown under it

A screenshot and the logs attached when a step fails are shown under the
step that failed.

- Given a file named "features/basket.feature" with

  ``` gherkin
  Feature: Basket
    Scenario: Add an item
      When I add an item
  ```

- And a file named "features/setup-steps.R" with

      when("I add an item", function(context) stop("The basket is full"))
      after_step(function(context, step) {
        if (step$status == "failed") {
          png("basket.png")
          plot(1:3)
          dev.off()
          context$attach(readBin("basket.png", "raw", file.size("basket.png")), "image/png", file_name = "basket.png")
          context$log("Opened the basket")
        }
      })

- When I run

      test("features", reporter = CucumberHtmlReporter$new("report.html"), stop_on_failure = FALSE)

- Then the HTML report "report.html" shows these attachments:

  |                    |       |                   |
  |--------------------|-------|-------------------|
  | step               | kind  | content           |
  | When I add an item | image | basket.png        |
  | When I add an item | text  | Opened the basket |

Source: `tests/acceptance/r-html_reporter.feature`

## See also

Steps and hooks attach screenshots and logs to the report, see
[attachments](https://jakubsob.github.io/cucumber/dev/reference/attachments.md)
and
[`vignette("reporting", package = "cucumber")`](https://jakubsob.github.io/cucumber/dev/articles/reporting.md).

## Super class

[`cucumber::CucumberReporter`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.md)
-\> `CucumberHtmlReporter`

## Public fields

- `file`:

  Path of the HTML file the report is written to

## Methods

### Public methods

- [`CucumberHtmlReporter$new()`](#method-CucumberHtmlReporter-new)

- [`CucumberHtmlReporter$start_run()`](#method-CucumberHtmlReporter-start_run)

- [`CucumberHtmlReporter$add_message()`](#method-CucumberHtmlReporter-add_message)

- [`CucumberHtmlReporter$end_run()`](#method-CucumberHtmlReporter-end_run)

- [`CucumberHtmlReporter$clone()`](#method-CucumberHtmlReporter-clone)

Inherited methods

- [`cucumber::CucumberReporter$add_warning()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.html#method-add_warning)
- [`cucumber::CucumberReporter$report()`](https://jakubsob.github.io/cucumber/dev/reference/CucumberReporter.html#method-report)

------------------------------------------------------------------------

### Method `new()`

Create an HTML reporter

#### Usage

    CucumberHtmlReporter$new(file = "cucumber-report.html")

#### Arguments

- `file`:

  Path of the HTML file to write, replaced by each run. A relative path
  is relative to the working directory when the reporter is created. Its
  directory is created when the reporter is, if it doesn't exist.

------------------------------------------------------------------------

### Method `start_run()`

Start collecting the messages of a run

#### Usage

    CucumberHtmlReporter$start_run()

------------------------------------------------------------------------

### Method `add_message()`

Collect a message of the run

#### Usage

    CucumberHtmlReporter$add_message(envelope)

#### Arguments

- `envelope`:

  A list with one element, named by the message's type

------------------------------------------------------------------------

### Method `end_run()`

Write the report

#### Usage

    CucumberHtmlReporter$end_run(error = NULL)

#### Arguments

- `error`:

  The error that stopped the run, or `NULL`

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    CucumberHtmlReporter$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
cucumber::test(reporter = cucumber::CucumberHtmlReporter$new("cucumber-report.html"))

# With the progress of the run
cucumber::test(reporter = cucumber::CucumberMultiReporter$new(list(
  cucumber::CucumberProgressReporter$new(),
  cucumber::CucumberHtmlReporter$new("cucumber-report.html")
)))

# From the messages of a run, after it ran
cucumber::test(reporter = cucumber::CucumberMessagesReporter$new("cucumber.ndjson"))
cucumber::CucumberHtmlReporter$new("cucumber-report.html")$report("cucumber.ndjson")
} # }
```

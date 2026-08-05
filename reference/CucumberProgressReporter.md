# Progress Reporter for Cucumber

A reporter that prints step-by-step progress to the console, mimicking
testthat::ProgressReporter but with visibility into individual Gherkin
steps.

## Details

Prints each step as it executes with a status indicator, grouped under
scenario and feature headers similar to testthat's output:

- [x] for passed steps (green)

- ✗ for failed/errored steps (red)

    Feature: Addition
      Scenario: Add two numbers
        ✓ Given I have entered 50 into the calculator
        ✓ Given I have entered 70 into the calculator
        ✓ When I press add
        ✓ Then the result should be 120 on the screen

### Usage

Pass a reporter instance to
[`test()`](https://jakubsobolewski.com/cucumber/reference/test.md) or
[`run()`](https://jakubsobolewski.com/cucumber/reference/run.md):

    # Step-level detail
    cucumber::test("tests/acceptance", reporter = cucumber::CucumberProgressReporter$new())

    # testthat reporters still work, reporting at the scenario level only
    cucumber::test("tests/acceptance", reporter = testthat::ProgressReporter$new())

    # Silent mode
    cucumber::test("tests/acceptance", reporter = testthat::SilentReporter$new())

    # From within a test file
    cucumber::run(reporter = cucumber::CucumberProgressReporter$new())

### Creating custom reporters

Extend
[CucumberReporter](https://jakubsobolewski.com/cucumber/reference/CucumberReporter.md)
to build your own:

    HTMLReporter <- R6::R6Class(
      "HTMLReporter",
      inherit = cucumber::CucumberReporter,
      public = list(
        html_output = character(),
        start_feature = function(feature_name) {
          super$start_feature(feature_name)
          self$html_output <- c(self$html_output, sprintf("<h2>%s</h2>", feature_name))
        },
        end_step = function(step) {
          super$end_step(step)
          status_class <- step$status %||% "passed"
          self$html_output <- c(
            self$html_output,
            sprintf('<div class="step %s">%s %s</div>', status_class, step$keyword, step$text)
          )
        },
        end_reporter = function() {
          if (!is.null(super$end_reporter)) super$end_reporter()
          writeLines(self$html_output, "test-report.html")
        }
      )
    )

### Step metadata

When `end_step()` is called, the step object contains:

- `keyword` - The step keyword (Given, When, Then, etc.)

- `text` - The step text

- `status` - One of "passed", "failed", or "error"

- `error` - The error object if the step failed or errored (NULL
  otherwise)

- `duration` - Execution time in seconds

- `data_table` - Data table if present (NULL otherwise)

- `docstring` - Docstring if present (NULL otherwise)

## See also

[CucumberReporter](https://jakubsobolewski.com/cucumber/reference/CucumberReporter.md)

## Super classes

[`testthat::Reporter`](https://testthat.r-lib.org/reference/Reporter.html)
-\>
[`cucumber::CucumberReporter`](https://jakubsobolewski.com/cucumber/reference/CucumberReporter.md)
-\> `CucumberProgressReporter`

## Public fields

- `show_praise`:

  Whether to show praise messages

- `step_count`:

  Number of steps executed

- `step_passed`:

  Number of steps that passed

- `step_failed`:

  Number of steps that failed

- `current_scenario`:

  Name of the scenario currently executing

- `current_steps`:

  Steps executed so far in the current scenario

- `failures`:

  Recorded failures for the end-of-run summary

- `step_errored`:

  Whether end_step already rendered an error this scenario

- `num_colors`:

  Terminal color support captured at construction

- `reporter_max_docstring_lines`:

  Max docstring lines to print per step

- `reporter_max_table_lines`:

  Max data table rows to print per step

## Methods

### Public methods

- [`CucumberProgressReporter$new()`](#method-CucumberProgressReporter-new)

- [`CucumberProgressReporter$start_feature()`](#method-CucumberProgressReporter-start_feature)

- [`CucumberProgressReporter$end_feature()`](#method-CucumberProgressReporter-end_feature)

- [`CucumberProgressReporter$start_test()`](#method-CucumberProgressReporter-start_test)

- [`CucumberProgressReporter$add_result()`](#method-CucumberProgressReporter-add_result)

- [`CucumberProgressReporter$start_step()`](#method-CucumberProgressReporter-start_step)

- [`CucumberProgressReporter$end_step()`](#method-CucumberProgressReporter-end_step)

- [`CucumberProgressReporter$print_step_args()`](#method-CucumberProgressReporter-print_step_args)

- [`CucumberProgressReporter$end_reporter()`](#method-CucumberProgressReporter-end_reporter)

- [`CucumberProgressReporter$clone()`](#method-CucumberProgressReporter-clone)

Inherited methods

- [`testthat::Reporter$.start_context()`](https://testthat.r-lib.org/reference/Reporter.html#method-.start_context)
- [`testthat::Reporter$cat_line()`](https://testthat.r-lib.org/reference/Reporter.html#method-cat_line)
- [`testthat::Reporter$cat_tight()`](https://testthat.r-lib.org/reference/Reporter.html#method-cat_tight)
- [`testthat::Reporter$end_context()`](https://testthat.r-lib.org/reference/Reporter.html#method-end_context)
- [`testthat::Reporter$end_context_if_started()`](https://testthat.r-lib.org/reference/Reporter.html#method-end_context_if_started)
- [`testthat::Reporter$end_file()`](https://testthat.r-lib.org/reference/Reporter.html#method-end_file)
- [`testthat::Reporter$end_test()`](https://testthat.r-lib.org/reference/Reporter.html#method-end_test)
- [`testthat::Reporter$is_full()`](https://testthat.r-lib.org/reference/Reporter.html#method-is_full)
- [`testthat::Reporter$local_user_output()`](https://testthat.r-lib.org/reference/Reporter.html#method-local_user_output)
- [`testthat::Reporter$rule()`](https://testthat.r-lib.org/reference/Reporter.html#method-rule)
- [`testthat::Reporter$start_context()`](https://testthat.r-lib.org/reference/Reporter.html#method-start_context)
- [`testthat::Reporter$start_file()`](https://testthat.r-lib.org/reference/Reporter.html#method-start_file)
- [`testthat::Reporter$start_reporter()`](https://testthat.r-lib.org/reference/Reporter.html#method-start_reporter)
- [`testthat::Reporter$update()`](https://testthat.r-lib.org/reference/Reporter.html#method-update)

------------------------------------------------------------------------

### Method `new()`

Initialize the reporter

#### Usage

    CucumberProgressReporter$new(
      show_praise = TRUE,
      reporter_max_docstring_lines = getOption("cucumber.reporter_max_docstring_lines", Inf),
      reporter_max_table_lines = getOption("cucumber.reporter_max_table_lines", Inf),
      ...
    )

#### Arguments

- `show_praise`:

  Whether to show praise (default TRUE)

- `reporter_max_docstring_lines`:

  Max docstring lines to print for a step before truncating. Defaults to
  the `cucumber.reporter_max_docstring_lines` option, or `Inf` (print in
  full) if unset.

- `reporter_max_table_lines`:

  Max data table rows to print for a step before truncating. Defaults to
  the `cucumber.reporter_max_table_lines` option, or `Inf` (print in
  full) if unset.

- `...`:

  Additional arguments passed to parent

------------------------------------------------------------------------

### Method `start_feature()`

Start a feature

#### Usage

    CucumberProgressReporter$start_feature(feature_name)

#### Arguments

- `feature_name`:

  Name of the feature

------------------------------------------------------------------------

### Method `end_feature()`

End the current feature

#### Usage

    CucumberProgressReporter$end_feature()

------------------------------------------------------------------------

### Method `start_test()`

Start a test (called by testthat for each scenario)

#### Usage

    CucumberProgressReporter$start_test(context, test)

#### Arguments

- `context`:

  Test context

- `test`:

  Test name (will be "Scenario: ")

------------------------------------------------------------------------

### Method `add_result()`

Add a result (warning, skip, failure, etc.)

#### Usage

    CucumberProgressReporter$add_result(context, test, result)

#### Arguments

- `context`:

  Test context

- `test`:

  Test object

- `result`:

  Test result object

------------------------------------------------------------------------

### Method `start_step()`

Start a step

#### Usage

    CucumberProgressReporter$start_step(step)

#### Arguments

- `step`:

  Pickle step object

------------------------------------------------------------------------

### Method `end_step()`

End a step and print its result

#### Usage

    CucumberProgressReporter$end_step(step)

#### Arguments

- `step`:

  Pickle step object with execution results

------------------------------------------------------------------------

### Method `print_step_args()`

Print a step's docstring and/or data table arguments, indented and
truncated to `reporter_max_docstring_lines` / `reporter_max_table_lines`

#### Usage

    CucumberProgressReporter$print_step_args(step)

#### Arguments

- `step`:

  Pickle step object

------------------------------------------------------------------------

### Method `end_reporter()`

Print summary at the end (called by testthat)

#### Usage

    CucumberProgressReporter$end_reporter()

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    CucumberProgressReporter$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Use with cucumber::test()
cucumber::test(
  "tests/acceptance",
  reporter = cucumber::CucumberProgressReporter$new()
)

# Or without praise messages
cucumber::test(
  "tests/acceptance",
  reporter = cucumber::CucumberProgressReporter$new(show_praise = FALSE)
)
} # }
```

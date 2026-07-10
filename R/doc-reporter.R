#' Cucumber Reporters
#'
#' @description
#' Cucumber reporters extend testthat's Reporter system to provide step-level
#' visibility during test execution. They work alongside testthat's reporters,
#' adding detailed progress information for individual Gherkin steps.
#'
#' @details
#' ## Reporter Types
#'
#' ### CucumberReporter
#'
#' The base class for all cucumber reporters. It extends `testthat::Reporter`
#' and adds hooks for step-level and feature-level events:
#'
#' - `start_feature(feature_name)` - Called before executing a feature
#' - `end_feature()` - Called after all scenarios in a feature complete
#' - `start_step(step)` - Called before executing a step
#' - `end_step(step)` - Called after a step completes
#'
#' ### CucumberProgressReporter
#'
#' A concrete implementation that prints step-by-step progress to the console,
#' similar to testthat's ProgressReporter but with step-level detail:
#'
#' ```
#' Feature: Addition
#'   ✓ Given I have entered 50 into the calculator
#'   ✓ And I have entered 70 into the calculator
#'   ✓ When I press add
#'   ✓ Then the result should be 120 on the screen
#' ```
#'
#' ## Usage
#'
#' ### With cucumber::test()
#'
#' Pass a reporter instance to `cucumber::test()`:
#'
#' ```r
#' # Use cucumber's CucumberProgressReporter for step-level detail
#' cucumber::test(
#'   "tests/acceptance",
#'   reporter = cucumber::CucumberProgressReporter$new()
#' )
#'
#' # Use testthat's reporter for scenario-level only (backward compatible)
#' cucumber::test(
#'   "tests/acceptance",
#'   reporter = testthat::ProgressReporter$new()
#' )
#'
#' # Silent mode
#' cucumber::test(
#'   "tests/acceptance",
#'   reporter = testthat::SilentReporter$new()
#' )
#' ```
#'
#' ### With cucumber::run()
#'
#' When using `run()` from within a test file:
#'
#' ```r
#' # In tests/testthat/test-cucumber.R
#' cucumber::run(reporter = cucumber::CucumberProgressReporter$new())
#' ```
#'
#' ## Creating Custom Reporters
#'
#' You can create custom reporters by extending CucumberReporter:
#'
#' ```r
#' HTMLReporter <- R6::R6Class(
#'   "HTMLReporter",
#'   inherit = cucumber::CucumberReporter,
#'   public = list(
#'     html_output = character(),
#'
#'     start_feature = function(feature_name) {
#'       super$start_feature(feature_name)
#'       self$html_output <- c(self$html_output,
#'                            sprintf("<h2>%s</h2>", feature_name))
#'     },
#'
#'     end_step = function(step) {
#'       super$end_step(step)
#'       status_class <- step$status %||% "passed"
#'       self$html_output <- c(
#'         self$html_output,
#'         sprintf(
#'           '<div class="step %s">%s %s</div>',
#'           status_class,
#'           step$keyword,
#'           step$text
#'         )
#'       )
#'     },
#'
#'     end_reporter = function() {
#'       if (!is.null(super$end_reporter)) {
#'         super$end_reporter()
#'       }
#'       # Write HTML to file
#'       writeLines(self$html_output, "test-report.html")
#'     }
#'   )
#' )
#' ```
#'
#' ## Backward Compatibility
#'
#' Cucumber reporters are fully backward compatible with testthat reporters:
#'
#' - testthat reporters work unchanged and report at the scenario level
#' - CucumberReporter adds step-level hooks without affecting testthat behavior
#' - You can switch between testthat and cucumber reporters without code changes
#'
#' ## Step Metadata
#'
#' When `end_step()` is called, the step object contains:
#'
#' - `keyword` - The step keyword (Given, When, Then, etc.)
#' - `text` - The step text
#' - `status` - One of "passed", "failed", or "error"
#' - `error` - The error object if the step failed or errored (NULL otherwise)
#' - `duration` - Execution time in seconds
#' - `data_table` - Data table if present (NULL otherwise)
#' - `docstring` - Docstring if present (NULL otherwise)
#'
#' @name reporters
#' @seealso [CucumberReporter], [CucumberProgressReporter], [cucumber::test()], [cucumber::run()]
#' @md
NULL

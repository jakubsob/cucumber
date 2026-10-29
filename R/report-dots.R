DOTS_CHARACTERS <- c(
  passed = ".",
  failed = "F",
  skipped = "-",
  pending = "P",
  undefined = "U",
  ambiguous = "A"
)

#' Dots Reporter for Cucumber
#'
#' @description
#' Prints one character for each step and hook as it finishes, then the summary of
#' [CucumberSummaryReporter]:
#'
#' ```
#' ......F--
#'
#' Failures:
#'
#' 1) Scenario: Remove an item # basket.feature:6
#'     ✔ Given a basket with 2 apples
#'     ✖ When I remove 3 apples
#'     Error:
#'       Can't remove more apples than there are.
#'
#' ────────────────────────────────────────────────────────────────────────
#' Summary
#'   3 scenarios (1 failed, 2 passed)
#'   9 steps (1 failed, 2 skipped, 6 passed)
#'   0m00.153s (executing steps: 0m00.121s)
#' ────────────────────────────────────────────────────────────────────────
#' ```
#'
#' @examples
#' \dontrun{
#' cucumber::test("tests/acceptance", reporter = cucumber::CucumberDotsReporter$new())
#' }
#'
#' @eval features_rd(features = "r-dots_reporter.feature")
#'
#' @export
CucumberDotsReporter <- R6::R6Class(
  "CucumberDotsReporter",
  inherit = CucumberSummaryReporter,
  public = list(
    #' @description
    #' Print a character for each step and hook that finished
    #' @param envelope A list with one element, named by the message's type
    add_message = function(envelope) {
      super$add_message(envelope)
      finished <- envelope$testStepFinished
      if (!is.null(finished)) {
        private$local_cli()
        status <- tolower(finished$testStepResult$status)
        cat(status_color(status)(DOTS_CHARACTERS[[status]]))
      }
      invisible(self)
    },

    #' @description
    #' End the line of characters and print the summary
    #' @param error The error that stopped the run, or `NULL`
    end_run = function(error = NULL) {
      cat("\n")
      super$end_run(error)
    }
  )
)

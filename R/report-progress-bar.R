#' Progress Bar Reporter for Cucumber
#'
#' @description
#' Shows a bar of the steps and hooks run so far, redrawn in place:
#'
#' ```
#' Feature: Basket
#'   Scenario: Remove an item
#'     ✔ Given a basket with 2 apples
#'     ✖ When I remove 3 apples
#'       Error:
#'         Can't remove more apples than there are.
#' 12/40 steps [==============                                         ]
#' ```
#'
#' @examples
#' \dontrun{
#' cucumber::test("tests/acceptance", reporter = cucumber::CucumberProgressBarReporter$new())
#' }
#'
#' @eval features_rd(features = "r-progress_bar_reporter.feature")
#'
#' @export
CucumberProgressBarReporter <- R6::R6Class(
  "CucumberProgressBarReporter",
  inherit = CucumberSummaryReporter,
  public = list(
    #' @field total Number of steps and hooks of the scenarios to run
    total = 0L,

    #' @field current Number of steps and hooks that finished
    current = 0L,

    #' @description
    #' Count the steps and hooks of each scenario, and advance the bar when one finishes
    #' @param envelope A list with one element, named by the message's type
    add_message = function(envelope) {
      super$add_message(envelope)
      if (!is.null(envelope$testCase)) {
        self$total <- self$total + length(envelope$testCase$testSteps)
      }
      if (!is.null(envelope$testStepFinished)) {
        self$current <- self$current + 1L
        self$draw_bar()
      }
      invisible(self)
    },

    #' @description
    #' Draw the bar
    draw_bar = function() {
      label <- sprintf("%d/%d steps ", self$current, self$total)
      size <- max(self$width - nchar(label) - 3L, 10L)
      done <- round(size * min(self$current / max(self$total, 1L), 1))
      self$draw(paste0(
        label,
        "[",
        strrep("=", done),
        strrep(" ", size - done),
        "]"
      ))
    },

    #' @description
    #' Clear the bar and print the error that stopped the run, if any, and the
    #' scenarios and steps counted by status. The scenarios that didn't pass
    #' were printed when they finished.
    #' @param error The error that stopped the run, or `NULL`
    end_run = function(error = NULL) {
      self$clear()
      self$live <- NULL
      self$print_run_error(error)
      self$print_undefined_parameter_types()
      self$print_counts()
      invisible(self)
    }
  ),
  private = list(
    # Print a scenario that didn't pass above the bar
    on_scenario_end = function(status) {
      failed <- !status %in% c("passed", "skipped")
      self$print_failures_since(length(self$failures) - failed)
    }
  )
)

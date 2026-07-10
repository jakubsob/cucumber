#' Cucumber Reporter Base Class
#'
#' @description
#' Base class for cucumber reporters that extends testthat::Reporter.
#' Adds step-level and feature-level reporting hooks while maintaining
#' full compatibility with testthat reporters.
#'
#' @details
#' CucumberReporter extends testthat's Reporter class to add:
#' - Feature-level hooks: `start_feature()`, `end_feature()`
#' - Step-level hooks: `start_step()`, `end_step()`
#'
#' These additional hooks are called during cucumber test execution to provide
#' visibility into individual step execution. Standard testthat reporters will
#' continue to work unchanged, reporting only at the scenario (test) level.
#'
#' @section Methods:
#' \describe{
#'   \item{`start_feature(feature_name)`}{Called before executing a feature's scenarios}
#'   \item{`end_feature()`}{Called after all scenarios in a feature complete}
#'   \item{`start_step(step)`}{Called before executing a step}
#'   \item{`end_step(step)`}{Called after a step completes, with status/error/duration populated}
#' }
#'
#' @importFrom R6 R6Class
#' @importFrom rlang %||%
#' @keywords internal
#' @export
CucumberReporter <- R6::R6Class(
  "CucumberReporter",
  inherit = testthat::Reporter,
  public = list(
    #' @field current_feature Current feature name being executed
    current_feature = NULL,

    #' @field current_pickle Current pickle (scenario) being executed
    current_pickle = NULL,

    #' @description
    #' Start a feature
    #' @param feature_name Name of the feature
    start_feature = function(feature_name) {
      self$current_feature <- feature_name
      invisible(self)
    },

    #' @description
    #' End the current feature
    end_feature = function() {
      self$current_feature <- NULL
      invisible(self)
    },

    #' @description
    #' Start a step
    #' @param step Pickle step object
    start_step = function(step) {
      invisible(self)
    },

    #' @description
    #' End a step (called after execution with status/error/duration populated)
    #' @param step Pickle step object with execution results
    end_step = function(step) {
      invisible(self)
    }
  )
)

#' Progress Reporter for Cucumber
#'
#' @description
#' A reporter that prints step-by-step progress to the console, mimicking
#' testthat::ProgressReporter but with visibility into individual steps.
#'
#' @details
#' Prints each step as it executes with a status indicator:
#' - ✓ for passed steps (green)
#' - ✗ for failed/errored steps (red)
#'
#' Groups steps under scenario and feature headers, similar to testthat's output.
#'
#' @examples
#' \dontrun{
#' # Use with cucumber::test()
#' cucumber::test(
#'   "tests/acceptance",
#'   reporter = cucumber::CucumberProgressReporter$new()
#' )
#'
#' # Or with verbose output
#' cucumber::test(
#'   "tests/acceptance",
#'   reporter = cucumber::CucumberProgressReporter$new(show_praise = FALSE)
#' )
#' }
#'
#' @export
CucumberProgressReporter <- R6::R6Class(
  "CucumberProgressReporter",
  inherit = CucumberReporter,
  public = list(
    #' @field show_praise Whether to show praise messages
    show_praise = TRUE,

    #' @field step_count Number of steps executed
    step_count = 0,

    #' @field step_passed Number of steps that passed
    step_passed = 0,

    #' @field step_failed Number of steps that failed
    step_failed = 0,

    #' @description
    #' Initialize the reporter
    #' @param show_praise Whether to show praise (default TRUE)
    #' @param ... Additional arguments passed to parent
    initialize = function(show_praise = TRUE, ...) {
      super$initialize(...)
      self$show_praise <- show_praise
      self$step_count <- 0
      self$step_passed <- 0
      self$step_failed <- 0
      invisible(self)
    },

    #' @description
    #' Start a feature
    #' @param feature_name Name of the feature
    start_feature = function(feature_name) {
      super$start_feature(feature_name)
      cat("\n", cli::col_blue(cli::style_bold(feature_name)), "\n", sep = "")
      invisible(self)
    },

    #' @description
    #' End the current feature
    end_feature = function() {
      super$end_feature()
      cat("\n")
      invisible(self)
    },

    #' @description
    #' Start a test (called by testthat for each scenario)
    #' @param context Test context
    #' @param test Test name (will be "Scenario: <name>")
    start_test = function(context, test) {
      if (!is.null(super$start_test)) {
        super$start_test(context, test)
      }
      cat("  ", cli::style_bold(test), "\n", sep = "")
      invisible(self)
    },

    #' @description
    #' Add a result (warning, skip, failure, etc.)
    #' @param context Test context
    #' @param test Test object
    #' @param result Test result object
    add_result = function(context, test, result) {
      if (!is.null(super$add_result)) {
        super$add_result(context, test, result)
      }

      # Display warnings
      if (inherits(result, "expectation_warning")) {
        warning_msg <- conditionMessage(result)
        warning_lines <- strsplit(warning_msg, "\n")[[1]]
        cat("    ", cli::col_yellow(cli::style_italic("Warning: ")), "\n", sep = "")
        for (line in warning_lines) {
          cat("      ", cli::col_yellow(line), "\n", sep = "")
        }
      }

      # Display errors that occur outside of test_that (e.g., during setup)
      if (inherits(result, "expectation_error") || inherits(result, "expectation_failure")) {
        cat("  ", cli::col_red(cli::style_bold("Error: ")), "\n", sep = "")
        error_msg <- conditionMessage(result)
        error_lines <- strsplit(error_msg, "\n")[[1]]
        for (line in error_lines) {
          cat("    ", cli::col_red(line), "\n", sep = "")
        }
      }

      invisible(self)
    },

    #' @description
    #' Start a step
    #' @param step Pickle step object
    start_step = function(step) {
      super$start_step(step)
      invisible(self)
    },

    #' @description
    #' End a step and print its result
    #' @param step Pickle step object with execution results
    end_step = function(step) {
      super$end_step(step)

      self$step_count <- self$step_count + 1

      status <- step$status %||% "passed"

      if (status == "passed") {
        self$step_passed <- self$step_passed + 1
        status_symbol <- cli::col_green(cli::symbol$tick)
      } else {
        self$step_failed <- self$step_failed + 1
        status_symbol <- cli::col_red(cli::symbol$cross)
      }

      # Format: "    ✓ Given I have 5 cucumbers"
      # ponytail: stdout so expect_snapshot can capture step output. Forgoes
      # forced ANSI color in a live terminal; add a colored-live path if anyone
      # actually needs it interactively.
      cat(
        "    ",
        status_symbol,
        " ",
        cli::style_bold(step$keyword),
        " ",
        step$text,
        "\n",
        sep = ""
      )

      # If step failed or errored, show error details
      if (!is.null(step$error)) {
        # Get error message - for rlang errors this includes full formatting
        error_msg <- conditionMessage(step$error)
        # Split multi-line error messages and indent each line
        error_lines <- strsplit(error_msg, "\n")[[1]]
        for (line in error_lines) {
          cat(
            "      ",
            cli::col_red(line),
            "\n",
            sep = ""
          )
        }
      }

      invisible(self)
    },

    #' @description
    #' Print summary at the end (called by testthat)
    end_reporter = function() {
      if (!is.null(super$end_reporter)) {
        super$end_reporter()
      }

      cat("\n")
      cat(cli::style_bold("Summary"), "\n", sep = "")
      cat(
        "  Total: ", self$step_count,
        " | Passed: ", cli::col_green(self$step_passed),
        " | Failed: ", cli::col_red(self$step_failed),
        "\n",
        sep = ""
      )

      invisible(self)
    }
  )
)

#' Get reporter from options
#'
#' @keywords internal
#' @noRd
get_reporter <- function() {
  getOption(".cucumber_reporter", default = CucumberProgressReporter$new())
}

#' Set reporter in options
#'
#' @param reporter Reporter instance
#' @keywords internal
#' @noRd
set_reporter <- function(reporter) {
  options(.cucumber_reporter = reporter)
  invisible(reporter)
}

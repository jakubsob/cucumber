#' Pretty Reporter for Cucumber
#'
#' @description
#' Prints each feature, scenario and step as it runs, then the summary of
#' [CucumberSummaryReporter]:
#'
#' ```
#' Feature: Addition
#'   Scenario: Add two numbers
#'     [x] Given I have entered 50 into the calculator
#'     [x] Given I have entered 70 into the calculator
#'     [x] When I press add
#'     [x] Then the result should be 120 on the screen
#' ```
#'
#' @seealso [CucumberReporter]
#' @md
#' @examples
#' \dontrun{
#' cucumber::test(
#'   "tests/acceptance",
#'   reporter = cucumber::CucumberPrettyReporter$new()
#' )
#' }
#'
#' @eval features_rd(features = "r-pretty_reporter.feature")
#'
#' @export
CucumberPrettyReporter <- R6::R6Class(
  "CucumberPrettyReporter",
  inherit = CucumberSummaryReporter,
  public = list(
    #' @field show_praise Whether to show praise messages
    show_praise = TRUE,

    #' @field reporter_max_docstring_lines Max docstring lines to print per step
    reporter_max_docstring_lines = Inf,

    #' @field reporter_max_table_lines Max data table rows to print per step
    reporter_max_table_lines = Inf,

    #' @field step_warnings Warnings of the step currently executing, printed under it
    step_warnings = NULL,

    #' @field step_attachments Lines of the attachments of the step currently executing, printed under it
    step_attachments = NULL,

    #' @field printed_rule The Rule last printed in the current feature, printed again only for a scenario of another Rule
    printed_rule = NULL,

    #' @description
    #' Initialize the reporter
    #' @param show_praise Whether to show praise (default TRUE)
    #' @param reporter_max_docstring_lines Max docstring lines to print for a step before
    #'   truncating. Defaults to the `cucumber.reporter_max_docstring_lines` option, or
    #'   `Inf` (print in full) if unset.
    #' @param reporter_max_table_lines Max data table rows to print for a step before
    #'   truncating. Defaults to the `cucumber.reporter_max_table_lines` option, or `Inf`
    #'   (print in full) if unset.
    #' @param file Path of a file to print to instead of the console, replaced
    #'   by each run, or `NULL`
    initialize = function(
      show_praise = TRUE,
      reporter_max_docstring_lines = getOption(
        "cucumber.reporter_max_docstring_lines",
        Inf
      ),
      reporter_max_table_lines = getOption(
        "cucumber.reporter_max_table_lines",
        Inf
      ),
      file = NULL
    ) {
      super$initialize(file)
      self$show_praise <- show_praise
      self$reporter_max_docstring_lines <- reporter_max_docstring_lines
      self$reporter_max_table_lines <- reporter_max_table_lines
      invisible(self)
    },

    #' @description
    #' Keep a step's warnings to print them under it, print the others as they're raised
    #' @param warning The warning
    add_warning = function(warning) {
      if (is.null(self$step_warnings)) {
        super$add_warning(warning)
      } else {
        self$step_warnings <- c(self$step_warnings, conditionMessage(warning))
      }
      invisible(self)
    },

    #' @description
    #' Print a step's docstring and/or data table arguments as they're written,
    #' indented and truncated to `reporter_max_docstring_lines` / `reporter_max_table_lines`
    #' @param step The step, with its `docstring` and its `data_table` rows
    print_step_args = function(step) {
      docstring <- NULL
      if (!is.null(step$docstring)) {
        doc <- step$docstring
        docstring <- c(
          paste0(doc$delimiter, doc$media_type %||% ""),
          truncate_lines(doc$lines, self$reporter_max_docstring_lines),
          doc$delimiter
        )
      }
      table <- NULL
      if (!is.null(step$data_table)) {
        rows <- format_data_table(step$data_table)
        # Keep the header, truncate only the body rows
        table <- c(
          rows[1],
          truncate_lines(rows[-1], self$reporter_max_table_lines)
        )
      }
      lines <- if (isTRUE(step$data_table_first)) c(table, docstring) else c(docstring, table)
      for (line in lines) {
        cat("      ", cli::style_dim(line), "\n", sep = "")
      }
      invisible(self)
    }
  ),
  private = list(
    on_feature_start = function() {
      withr::local_options(
        cli.num_colors = self$num_colors,
        cli.unicode = self$unicode
      )
      cat("\n", bold_label(self$current_feature), "\n", sep = "")
      self$printed_rule <- NULL
    },

    on_feature_end = function() {
      cat("\n")
    },

    on_scenario_start = function() {
      withr::local_options(
        cli.num_colors = self$num_colors,
        cli.unicode = self$unicode
      )
      if (!is.null(self$current_rule) && !identical(self$current_rule, self$printed_rule)) {
        cat("  ", bold_label(self$current_rule), "\n", sep = "")
        self$printed_rule <- self$current_rule
      }
      cat("  ", bold_label(self$current_scenario), "\n", sep = "")
    },

    # Collect the step's warnings and attachments, to print them under it
    on_step_start = function() {
      self$step_warnings <- character()
      self$step_attachments <- character()
    },

    # Print an attachment under its step, or as it comes, of a hook
    on_attachment = function(attachment) {
      lines <- format_attachment(attachment)
      if (is.null(self$step_attachments)) {
        withr::local_options(
          cli.num_colors = self$num_colors,
          cli.unicode = self$unicode
        )
        for (line in lines) {
          cat("    ", cli::style_dim(line), "\n", sep = "")
        }
      } else {
        self$step_attachments <- c(self$step_attachments, lines)
      }
    },

    # Print the step, its arguments, warnings and error
    on_step_end = function(step) {
      withr::local_options(
        cli.num_colors = self$num_colors,
        cli.unicode = self$unicode
      )
      # ponytail: cat to stdout so expect_snapshot can capture step output; color
      # is re-enabled via the num_colors option forced above.
      print_step(step)
      self$print_step_args(step)
      for (line in self$step_attachments) {
        cat("      ", cli::style_dim(line), "\n", sep = "")
      }
      self$step_attachments <- NULL
      for (warning in self$step_warnings) {
        print_warning(warning)
      }
      self$step_warnings <- NULL
      print_step_error(step)
    },

    # Print the error of a hook that failed or is pending, or the reason of
    # one that skipped the scenario
    on_hook_end = function(hook) {
      withr::local_options(
        cli.num_colors = self$num_colors,
        cli.unicode = self$unicode
      )
      print_error(hook$error, hook$status)
    }
  )
)

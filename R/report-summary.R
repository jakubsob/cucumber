#' Summary Reporter for Cucumber
#'
#' @description
#' Prints only the summary of the run. [CucumberProgressReporter],
#' [CucumberPrettyReporter] and [CucumberDotsReporter] print it at the end of
#' the run too, and [CucumberProgressBarReporter] prints its counts.
#'
#' ```
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
#'   2 scenarios (1 failed, 1 passed)
#'   6 steps (1 failed, 5 passed)
#'   0m00.153s (executing steps: 0m00.121s)
#' ────────────────────────────────────────────────────────────────────────
#' ```
#'
#' The scenarios that failed, are ambiguous or undefined are listed under
#' Failures, those that are pending and the failed attempts of retried
#' scenarios under Warnings.
#'
#' @examples
#' \dontrun{
#' cucumber::test("tests/acceptance", reporter = cucumber::CucumberSummaryReporter$new())
#' }
#'
#' @eval features_rd(features = "r-summary_reporter.feature")
#'
#' @export
CucumberSummaryReporter <- R6::R6Class(
  "CucumberSummaryReporter",
  inherit = CucumberQueryReporter,
  public = list(
    #' @field scenario_statuses Statuses of the finished scenarios
    scenario_statuses = NULL,

    #' @field current_feature Name of the feature currently executing, like `"Feature: Basket"`
    current_feature = NULL,

    #' @field current_scenario Name of the scenario currently executing, like `"Scenario: Add an item"`
    current_scenario = NULL,

    #' @field current_rule Name of the Rule of the scenario currently executing, like
    #'   `"Rule: Removing items"`, or `NULL`
    current_rule = NULL,

    #' @field failures The scenarios that didn't pass or skip, printed as they finish by some reporters
    failures = NULL,

    #' @field issues The scenarios listed in the summary: those that didn't pass or skip, and the
    #'   failed attempts of retried scenarios, in the order they finished
    issues = NULL,

    #' @field undefined_parameter_types Parameter types used by step definitions but not defined
    undefined_parameter_types = NULL,

    #' @field num_colors Terminal color support captured at construction
    num_colors = 1L,

    #' @field unicode Whether the terminal shows Unicode symbols, captured at construction
    unicode = FALSE,

    #' @field dynamic Whether the terminal can redraw a line, captured at construction
    dynamic = FALSE,

    #' @field width Width of the terminal, captured at construction
    width = 80L,

    #' @field live The line drawn by `draw()`, redrawn after printing above it
    live = NULL,

    #' @description
    #' Initialize the reporter
    #' @param file Path of a file to print to instead of the console, replaced
    #'   by each run, or `NULL`. A relative path is relative to the working
    #'   directory when the reporter is created. Its directory is created when
    #'   the reporter is, if it doesn't exist.
    initialize = function(file = NULL) {
      self$scenario_statuses <- character()
      self$failures <- list()
      self$issues <- list()
      private$query <- new_query()
      # ponytail: capture real color support now, before testthat runs. During a
      # test, output is sunk and cli auto-detects 0 colors; forcing this captured
      # value at each print site re-enables color live while snapshots (built
      # non-interactively -> num_colors = 1) stay plain.
      self$num_colors <- cli::num_ansi_colors()
      # Captured now too: testthat turns them off while it runs a test
      self$unicode <- cli::is_utf8_output()
      self$dynamic <- cli::is_dynamic_tty()
      self$width <- cli::console_width()
      if (!is.null(file)) {
        self$output <- report_path(file)
        # A file has no colors and can't redraw a line
        self$num_colors <- 1L
        self$dynamic <- FALSE
      }
      invisible(self)
    },

    #' @description
    #' Draw a line that is redrawn in place, like a progress bar, in a terminal
    #' that can redraw a line
    #' @param text The line
    draw = function(text) {
      self$live <- text
      if (self$dynamic) {
        private$local_cli()
        text <- cli::ansi_strtrim(text, self$width - 1L)
        cat(
          "\r",
          text,
          strrep(" ", max(self$width - 1L - cli::ansi_nchar(text), 0L)),
          sep = ""
        )
      }
      invisible(self)
    },

    #' @description
    #' Clear the line drawn by `draw()`, to print below it what would be printed over it
    clear = function() {
      if (self$dynamic && !is.null(self$live)) {
        cat("\r", strrep(" ", self$width - 1L), "\r", sep = "")
      }
      invisible(self)
    },

    #' @description
    #' Print above the line drawn by `draw()`, then draw it again
    #' @param code Code that prints
    print_above = function(code) {
      private$local_cli()
      self$clear()
      force(code)
      if (!is.null(self$live)) {
        self$draw(self$live)
      }
      invisible(self)
    },

    #' @description
    #' Print the scenarios that didn't pass after the first `n` above the line
    #' drawn by `draw()`
    #' @param n Number of failures already printed
    print_failures_since = function(n) {
      for (failure in self$failures[seq_along(self$failures) > n]) {
        self$print_above(print_failure(failure))
      }
      invisible(self)
    },

    #' @description
    #' Follow the run's features, scenarios, steps and hooks in its messages
    #' @param envelope A list with one element, named by the message's type
    add_message = function(envelope) {
      super$add_message(envelope)
      q <- private$query
      message <- envelope[[1]]
      switch(
        names(envelope),
        undefinedParameterType = self$undefined_parameter_types[[
          message$name
        ]] <- message$expression,
        attachment = private$on_attachment(message),
        testCaseStarted = {
          pickle <- q$pickle_of(message)
          lineage <- q$lineage_of(pickle)
          if (
            is.null(private$feature_uri) ||
              !identical(pickle$uri %||% "", private$feature_uri)
          ) {
            private$finish_feature()
            private$feature_uri <- pickle$uri %||% ""
            self$current_feature <- feature_label(lineage$feature)
            private$on_feature_start()
          }
          self$current_rule <- if (!is.null(lineage$rule)) paste0(lineage$rule$keyword, ": ", lineage$rule$name)
          private$scenario_name <- paste0(lineage$scenario$keyword, ": ", pickle$name)
          self$current_scenario <- paste0(
            private$scenario_name,
            if (message$attempt > 0) paste0(" (attempt ", message$attempt + 1, ")")
          )
          private$on_scenario_start()
        },
        testStepStarted = {
          if (q$is_pickle_step(message)) {
            private$on_step_start()
          }
        },
        testStepFinished = {
          scenario <- q$scenario_of(q$started_of(message))
          if (q$is_pickle_step(message)) {
            private$on_step_end(scenario$steps[[length(scenario$steps)]])
          } else if (!is.null(message$testStepResult$message)) {
            private$on_hook_end(scenario$hooks[[length(scenario$hooks)]])
          }
        },
        testCaseFinished = {
          started <- q$started_of(message)
          scenario <- q$scenario_of(started)
          failure <- list(
            feature = self$current_feature,
            scenario = self$current_scenario,
            location = paste0(scenario$pickle$uri, ":", scenario$pickle$location$line),
            status = scenario$status,
            steps = scenario$steps,
            hooks = scenario$hooks
          )
          # Only the last attempt of a scenario is counted. A failed one
          # that will be retried is a warning of the summary.
          if (isTRUE(message$willBeRetried)) {
            failure$scenario <- paste0(private$scenario_name, " (attempt ", started$attempt + 1, ", retried)")
            failure$retried <- TRUE
            self$issues <- c(self$issues, list(failure))
            return(invisible(self))
          }
          self$scenario_statuses <- c(self$scenario_statuses, scenario$status)
          if (!scenario$status %in% c("passed", "skipped")) {
            self$failures <- c(self$failures, list(failure))
            self$issues <- c(self$issues, list(failure))
          }
          private$on_scenario_end(scenario$status)
        },
        testRunFinished = private$finish_feature()
      )
      invisible(self)
    },

    #' @description
    #' Print a warning as it's raised
    #' @param warning The warning
    add_warning = function(warning) {
      super$add_warning(warning)
      self$print_above(print_warning(conditionMessage(warning)))
      invisible(self)
    },

    #' @description
    #' Print the error that stopped the run
    #' @param error The error, or `NULL`
    print_run_error = function(error) {
      if (!is.null(error)) {
        self$print_above(print_error(conditionMessage(error)))
      }
      invisible(self)
    },

    #' @description
    #' Print the scenarios and steps counted by status
    print_counts = function() {
      private$local_cli()
      cat("\n")
      cat(cli::rule(), "\n", sep = "")
      cat(cli::style_bold("Summary"), "\n", sep = "")
      cat(
        "  ",
        format_status_counts(self$scenario_statuses, "scenario"),
        "\n",
        sep = ""
      )
      q <- private$query
      # Only the last attempt of each scenario is counted
      step_statuses <- unlist(lapply(q$test_cases_started_final(), \(started) {
        vapply(q$scenario_of(started)$steps, \(step) step$status, character(1))
      }))
      cat(
        "  ",
        format_status_counts(step_statuses %||% character(), "step"),
        "\n",
        sep = ""
      )
      # A run stopped before it finished has no duration
      if (q$run_finished()) {
        cat(
          "  ",
          format_duration(q$run_millis()),
          " (executing steps: ", format_duration(q$steps_millis()), ")\n",
          sep = ""
        )
      }
      cat(cli::rule(), "\n", sep = "")
      invisible(self)
    },

    #' @description
    #' Print each undefined parameter type, with the last step definition that used it
    print_undefined_parameter_types = function() {
      private$local_cli()
      types <- self$undefined_parameter_types
      if (length(types) > 0) {
        cat("\n", cli::col_yellow("Undefined parameter types:"), "\n", sep = "")
        cat(sprintf("- \"%s\" e.g. `%s`\n", names(types), types), sep = "")
      }
      invisible(self)
    },

    #' @description
    #' Print the scenarios that didn't pass, numbered and with where they are:
    #' under Failures those that failed, are ambiguous or undefined, under
    #' Warnings those that are pending and the failed attempts that were retried
    print_failures = function() {
      private$local_cli()
      warning <- vapply(self$issues, \(issue) isTRUE(issue$retried) || issue$status == "pending", logical(1))
      for (title in c("Failures", "Warnings")) {
        issues <- self$issues[if (title == "Failures") !warning else warning]
        if (length(issues) == 0) next
        cat("\n", cli::style_bold(paste0(title, ":")), "\n", sep = "")
        for (i in seq_along(issues)) {
          print_failure(issues[[i]], number = i)
        }
      }
      invisible(self)
    },

    #' @description
    #' Print the error that stopped the run, if any, and the summary
    #' @param error The error that stopped the run, or `NULL`
    end_run = function(error = NULL) {
      super$end_run(error)
      # A run stopped by an error of a reporter has no testRunFinished
      private$finish_feature()
      self$print_run_error(error)
      self$print_undefined_parameter_types()
      self$print_failures()
      self$print_counts()
      invisible(self)
    }
  ),
  private = list(
    query = NULL,
    feature_uri = NULL,
    # The current scenario's keyword and name
    scenario_name = NULL,

    finish_feature = function() {
      if (!is.null(private$feature_uri)) {
        private$on_feature_end()
        private$feature_uri <- NULL
        self$current_feature <- NULL
      }
    },

    # cli's colors and unicode as captured when the reporter was made, until the caller returns
    local_cli = function(frame = parent.frame()) {
      withr::local_options(cli.num_colors = self$num_colors, cli.unicode = self$unicode, .local_envir = frame)
    },

    # What the reporters print as the run goes: each does nothing here
    on_feature_start = function() NULL,
    on_feature_end = function() NULL,
    on_scenario_start = function() NULL,
    on_scenario_end = function(status) NULL,
    on_step_start = function() NULL,
    on_step_end = function(step) NULL,
    on_hook_end = function(hook) NULL,
    on_attachment = function(attachment) NULL
  )
)

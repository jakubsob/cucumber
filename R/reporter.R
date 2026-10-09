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
#'   \item{`end_hook(status, error)`}{Called after a scenario's hooks if one of them didn't pass}
#' }
#'
#' @importFrom R6 R6Class
#' @importFrom rlang %||%
#' @importFrom purrr map2_chr
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
    },

    #' @description
    #' Called after a scenario's `before` or `after` hooks if one of them didn't pass
    #' @param status `"failed"` or `"pending"`
    #' @param error The hook's error
    end_hook = function(status, error) {
      invisible(self)
    }
  )
)

#' Bold the label (text up to and including the first colon), name left plain
#'
#' e.g. "Feature: Addition" -> bold "Feature:" + " Addition"
#'
#' @keywords internal
#' @noRd
bold_label <- function(x) {
  colon <- regexpr(":", x, fixed = TRUE)
  if (colon == -1) {
    return(x)
  }
  paste0(cli::style_bold(substr(x, 1, colon)), substr(x, colon + 1, nchar(x)))
}

#' Render a data table (tibble) as aligned Gherkin pipe rows
#'
#' @keywords internal
#' @noRd
format_data_table <- function(tbl) {
  cells <- rbind(names(tbl), as.matrix(tbl))
  widths <- apply(cells, 2, \(col) max(nchar(col)))
  apply(cells, 1, \(row) {
    padded <- mapply(\(cell, w) formatC(cell, width = w, flag = "-"), row, widths)
    paste0("| ", paste(padded, collapse = " | "), " |")
  })
}

#' Truncate lines to max_lines, appending a "... N more lines" marker
#'
#' @keywords internal
#' @noRd
truncate_lines <- function(lines, max_lines) {
  if (length(lines) <= max_lines) {
    return(lines)
  }
  c(
    lines[seq_len(max_lines)],
    sprintf("... and %d more line(s)", length(lines) - max_lines)
  )
}

#' Order of step statuses from the worst to the best, as in Cucumber summaries
#'
#' @keywords internal
#' @noRd
STEP_STATUSES <- c("failed", "ambiguous", "undefined", "pending", "skipped", "passed")

status_color <- function(status) {
  switch(
    status,
    passed = cli::col_green,
    skipped = cli::col_cyan,
    pending = ,
    undefined = cli::col_yellow,
    cli::col_red
  )
}

status_symbol <- function(status) {
  symbol <- switch(
    status,
    passed = cli::symbol$tick,
    failed = cli::symbol$cross,
    skipped = "-",
    pending = "P",
    undefined = "U",
    ambiguous = "A"
  )
  status_color(status)(symbol)
}

#' Count statuses like Cucumber does, e.g. "3 steps (1 failed, 2 passed)"
#'
#' @keywords internal
#' @noRd
format_status_counts <- function(statuses, noun) {
  label <- paste0(length(statuses), " ", noun, if (length(statuses) != 1) "s")
  counts <- table(factor(statuses, STEP_STATUSES))
  counts <- counts[counts > 0]
  if (length(counts) == 0) {
    return(label)
  }
  parts <- map2_chr(names(counts), counts, \(status, n) status_color(status)(paste(n, status)))
  paste0(label, " (", paste(parts, collapse = ", "), ")")
}

#' Progress Reporter for Cucumber
#'
#' @description
#' A reporter that prints step-by-step progress to the console, mimicking
#' testthat::ProgressReporter but with visibility into individual Gherkin steps.
#'
#' @details
#' Prints each step as it executes with a status indicator, grouped under
#' scenario and feature headers similar to testthat's output:
#'
#' - \ifelse{latex}{[x]}{✓} for passed steps (green)
#' - \ifelse{latex}{[ ]}{✗} for failed steps (red)
#' - `-` for skipped steps (cyan)
#' - `P` for pending steps (yellow)
#' - `U` for undefined steps (yellow)
#' - `A` for ambiguous steps (red)
#'
#' The summary counts scenarios and steps by status, like Cucumber does.
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
#' ## Usage
#'
#' Pass a reporter instance to [cucumber::test()] or [cucumber::run()]:
#'
#' ```r
#' # Step-level detail
#' cucumber::test("tests/acceptance", reporter = cucumber::CucumberProgressReporter$new())
#'
#' # testthat reporters still work, reporting at the scenario level only
#' cucumber::test("tests/acceptance", reporter = testthat::ProgressReporter$new())
#'
#' # Silent mode
#' cucumber::test("tests/acceptance", reporter = testthat::SilentReporter$new())
#'
#' # From within a test file
#' cucumber::run(reporter = cucumber::CucumberProgressReporter$new())
#' ```
#'
#' ## Creating custom reporters
#'
#' Extend [CucumberReporter] to build your own:
#'
#' ```r
#' HTMLReporter <- R6::R6Class(
#'   "HTMLReporter",
#'   inherit = cucumber::CucumberReporter,
#'   public = list(
#'     html_output = character(),
#'     start_feature = function(feature_name) {
#'       super$start_feature(feature_name)
#'       self$html_output <- c(self$html_output, sprintf("<h2>%s</h2>", feature_name))
#'     },
#'     end_step = function(step) {
#'       super$end_step(step)
#'       status_class <- step$status %||% "passed"
#'       self$html_output <- c(
#'         self$html_output,
#'         sprintf('<div class="step %s">%s %s</div>', status_class, step$keyword, step$text)
#'       )
#'     },
#'     end_reporter = function() {
#'       if (!is.null(super$end_reporter)) super$end_reporter()
#'       writeLines(self$html_output, "test-report.html")
#'     }
#'   )
#' )
#' ```
#'
#' ## Step metadata
#'
#' When `end_step()` is called, the step object contains:
#'
#' - `keyword` - The step keyword as written (Given, When, Then, And, But or *)
#' - `type` - "Context", "Action" or "Outcome" for Given, When and Then steps,
#'   And and But steps take the type of the previous step. "Unknown" for `*`
#'   and for And or But as the first step.
#' - `text` - The step text
#' - `status` - One of "passed", "failed", "skipped", "pending", "undefined" or "ambiguous"
#' - `error` - The error object if the step failed, is pending, undefined or ambiguous (NULL otherwise)
#' - `duration` - Execution time in seconds
#' - `data_table` - Data table if present (NULL otherwise)
#' - `docstring` - Docstring if present (NULL otherwise)
#'
#' @seealso [CucumberReporter]
#' @md
#' @examples
#' \dontrun{
#' # Use with cucumber::test()
#' cucumber::test(
#'   "tests/acceptance",
#'   reporter = cucumber::CucumberProgressReporter$new()
#' )
#'
#' # Or without praise messages
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

    #' @field step_statuses Statuses of the reported steps
    step_statuses = NULL,

    #' @field scenario_statuses Statuses of the finished scenarios
    scenario_statuses = NULL,

    #' @field scenario_failed Whether testthat reported a failure or an error for the current scenario
    scenario_failed = FALSE,

    #' @field current_scenario Name of the scenario currently executing
    current_scenario = NULL,

    #' @field current_steps Steps executed so far in the current scenario
    current_steps = NULL,

    #' @field hook_statuses Statuses of the current scenario's hooks that didn't pass
    hook_statuses = NULL,

    #' @field failures Recorded failures for the end-of-run summary
    failures = NULL,

    #' @field step_errored Whether end_step already rendered a step's error this scenario
    step_errored = FALSE,

    #' @field num_colors Terminal color support captured at construction
    num_colors = 1L,

    #' @field reporter_max_docstring_lines Max docstring lines to print per step
    reporter_max_docstring_lines = Inf,

    #' @field reporter_max_table_lines Max data table rows to print per step
    reporter_max_table_lines = Inf,

    #' @description
    #' Initialize the reporter
    #' @param show_praise Whether to show praise (default TRUE)
    #' @param reporter_max_docstring_lines Max docstring lines to print for a step before
    #'   truncating. Defaults to the `cucumber.reporter_max_docstring_lines` option, or
    #'   `Inf` (print in full) if unset.
    #' @param reporter_max_table_lines Max data table rows to print for a step before
    #'   truncating. Defaults to the `cucumber.reporter_max_table_lines` option, or `Inf`
    #'   (print in full) if unset.
    #' @param ... Additional arguments passed to parent
    initialize = function(
      show_praise = TRUE,
      reporter_max_docstring_lines = getOption(
        "cucumber.reporter_max_docstring_lines",
        Inf
      ),
      reporter_max_table_lines = getOption("cucumber.reporter_max_table_lines", Inf),
      ...
    ) {
      super$initialize(...)
      self$show_praise <- show_praise
      self$reporter_max_docstring_lines <- reporter_max_docstring_lines
      self$reporter_max_table_lines <- reporter_max_table_lines
      self$step_statuses <- character()
      self$scenario_statuses <- character()
      self$current_steps <- list()
      self$failures <- list()
      # ponytail: capture real color support now, before testthat runs. During a
      # test, output is sunk and cli auto-detects 0 colors; forcing this captured
      # value at each print site re-enables color live while snapshots (built
      # non-interactively -> num_colors = 1) stay plain.
      self$num_colors <- cli::num_ansi_colors()
      invisible(self)
    },

    #' @description
    #' Start a feature
    #' @param feature_name Name of the feature
    start_feature = function(feature_name) {
      super$start_feature(feature_name)
      withr::local_options(cli.num_colors = self$num_colors)
      cat("\n", bold_label(feature_name), "\n", sep = "")
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
    #' @param test Test name (will be "Scenario: `<name>`")
    start_test = function(context, test) {
      if (!is.null(super$start_test)) {
        super$start_test(context, test)
      }
      self$current_scenario <- test
      self$current_steps <- list()
      self$hook_statuses <- character()
      self$step_errored <- FALSE
      self$scenario_failed <- FALSE
      withr::local_options(cli.num_colors = self$num_colors)
      cat("  ", bold_label(test), "\n", sep = "")
      invisible(self)
    },

    #' @description
    #' End a test (called by testthat for each scenario). The scenario gets the
    #' status of its worst step, or "failed" if a hook failed.
    #' @param context Test context
    #' @param test Test name
    end_test = function(context, test) {
      if (!is.null(super$end_test)) {
        super$end_test(context, test)
      }
      statuses <- vapply(self$current_steps, \(step) step$status %||% "passed", character(1))
      statuses <- c(statuses, self$hook_statuses)
      status <- STEP_STATUSES[STEP_STATUSES %in% c(statuses, "passed")][[1]]
      if (self$scenario_failed && status %in% c("passed", "skipped")) {
        status <- "failed"
      }
      self$scenario_statuses <- c(self$scenario_statuses, status)
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

      withr::local_options(cli.num_colors = self$num_colors)

      if (inherits(result, c("expectation_error", "expectation_failure"))) {
        self$scenario_failed <- TRUE
      }

      # Display warnings
      if (inherits(result, "expectation_warning")) {
        warning_msg <- conditionMessage(result)
        warning_lines <- strsplit(warning_msg, "\n")[[1]]
        cat(
          "    ",
          cli::col_yellow(cli::style_italic("Warning: ")),
          "\n",
          sep = ""
        )
        for (line in warning_lines) {
          cat("      ", cli::col_yellow(line), "\n", sep = "")
        }
      }

      # Display errors that occur outside of test_that (e.g., during setup).
      # Skip step errors already rendered by end_step to avoid double reporting.
      if (
        !self$step_errored &&
          (inherits(result, "expectation_error") ||
            inherits(result, "expectation_failure"))
      ) {
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
    #' Record the status of a scenario's hook that didn't pass
    #' @param status `"failed"` or `"pending"`
    #' @param error The hook's error
    end_hook = function(status, error) {
      super$end_hook(status, error)
      self$hook_statuses <- c(self$hook_statuses, status)
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

      withr::local_options(cli.num_colors = self$num_colors)

      self$current_steps <- c(self$current_steps, list(step))

      status <- step$status %||% "passed"
      self$step_statuses <- c(self$step_statuses, status)

      if (!status %in% c("passed", "skipped")) {
        self$step_errored <- TRUE
        self$failures <- c(
          self$failures,
          list(list(
            feature = self$current_feature,
            scenario = self$current_scenario,
            steps = self$current_steps
          ))
        )
      }

      # Format: "    ✓ Given I have 5 cucumbers"
      # ponytail: cat to stdout so expect_snapshot can capture step output; color
      # is re-enabled via the num_colors option forced above.
      cat(
        "    ",
        status_symbol(status),
        " ",
        cli::style_bold(step$keyword),
        " ",
        step$text,
        "\n",
        sep = ""
      )

      self$print_step_args(step)

      # If the step didn't pass, show why
      if (!is.null(step$error)) {
        # Get error message - for rlang errors this includes full formatting
        error_msg <- conditionMessage(step$error)
        # Split multi-line error messages and indent each line
        error_lines <- strsplit(error_msg, "\n")[[1]]
        for (line in error_lines) {
          cat(
            "      ",
            status_color(status)(line),
            "\n",
            sep = ""
          )
        }
      }

      invisible(self)
    },

    #' @description
    #' Print a step's docstring and/or data table arguments, indented and
    #' truncated to `reporter_max_docstring_lines` / `reporter_max_table_lines`
    #' @param step Pickle step object
    print_step_args = function(step) {
      if (!is.null(step$docstring)) {
        body <- truncate_lines(step$docstring, self$reporter_max_docstring_lines)
        for (line in c('"""', body, '"""')) {
          cat("      ", cli::style_dim(line), "\n", sep = "")
        }
      }
      if (!is.null(step$data_table)) {
        rows <- format_data_table(step$data_table)
        # Keep the header, truncate only the body rows
        rows <- c(rows[1], truncate_lines(rows[-1], self$reporter_max_table_lines))
        for (line in rows) {
          cat("      ", cli::style_dim(line), "\n", sep = "")
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

      withr::local_options(cli.num_colors = self$num_colors)

      cat("\n")
      cat(cli::rule(), "\n", sep = "")
      cat(cli::style_bold("Summary"), "\n", sep = "")
      cat("  ", format_status_counts(self$scenario_statuses, "scenario"), "\n", sep = "")
      cat("  ", format_status_counts(self$step_statuses, "step"), "\n", sep = "")
      cat(cli::rule(), "\n", sep = "")

      if (length(self$failures) > 0) {
        cat("\n", cli::style_bold("Failures"), "\n", sep = "")
        for (failure in self$failures) {
          cat("\n", bold_label(failure$feature %||% ""), "\n", sep = "")
          cat("  ", bold_label(failure$scenario %||% ""), "\n", sep = "")
          for (step in failure$steps) {
            status <- step$status %||% "passed"
            cat(
              "    ",
              status_symbol(status),
              " ",
              cli::style_bold(step$keyword),
              " ",
              step$text,
              "\n",
              sep = ""
            )
            if (!is.null(step$error)) {
              error_lines <- strsplit(conditionMessage(step$error), "\n")[[1]]
              for (line in error_lines) {
                cat("      ", status_color(status)(line), "\n", sep = "")
              }
            }
          }
        }
      }

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

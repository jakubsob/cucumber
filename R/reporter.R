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
#' - Every [Cucumber Message](https://github.com/cucumber/messages) of the run: `add_message()`
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
#'   \item{`end_hook(status, error)`}{Called after a scenario's `before` or `after` hook that failed, is pending or skipped the scenario}
#'   \item{`end_scenario(status)`}{Called after a scenario's steps and hooks, with the worst of their statuses}
#'   \item{`add_message(envelope)`}{Called with each Cucumber Message of the run, see [CucumberMessagesReporter]}
#' }
#'
#' Combine reporters with [CucumberMultiReporter].
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
    #' Called after a scenario's `before` or `after` hook that failed, is pending or skipped the scenario
    #' @param status `"failed"`, `"pending"` or `"skipped"`
    #' @param error The hook's error
    end_hook = function(status, error) {
      invisible(self)
    },

    #' @description
    #' Called after a scenario's steps and hooks, with the worst of their statuses
    #' @param status The scenario's status
    end_scenario = function(status) {
      invisible(self)
    },

    #' @description
    #' Called with each Cucumber Message of the run
    #' @param envelope A list with one element, named by the message's type,
    #'   like `list(testCaseStarted = list(...))`
    add_message = function(envelope) {
      invisible(self)
    }
  )
)

#' Call a cucumber event on a reporter. Reporters that aren't a
#' CucumberReporter don't get cucumber events.
#' @keywords internal
#' @noRd
cucumber_event <- function(reporter, method, ...) {
  if (inherits(reporter, "CucumberReporter")) {
    reporter[[method]](...)
  }
  invisible()
}

#' Combine reporters
#'
#' @description
#' Passes every call to each of its reporters, like [testthat::MultiReporter],
#' and is a [CucumberReporter] itself: its reporters that are
#' `CucumberReporter`s also get the step, hook, scenario and message calls.
#' Use it, for example, to print the progress of a run and write its
#' messages.
#'
#' @examples
#' \dontrun{
#' cucumber::test(reporter = cucumber::CucumberMultiReporter$new(list(
#'   cucumber::CucumberProgressReporter$new(),
#'   cucumber::CucumberMessagesReporter$new("cucumber.ndjson")
#' )))
#' }
#'
#' @export
CucumberMultiReporter <- R6::R6Class(
  "CucumberMultiReporter",
  inherit = CucumberReporter,
  public = list(
    #' @field reporters The reporters to pass the calls to
    reporters = list(),

    #' @description
    #' Combine reporters
    #' @param reporters A list of reporters, testthat ones or `CucumberReporter`s
    initialize = function(reporters = list()) {
      super$initialize()
      self$reporters <- reporters
    },

    #' @description Pass to each reporter
    start_reporter = function() private$each("start_reporter"),
    #' @description Pass to each reporter
    #' @param filename Test file name
    start_file = function(filename) private$each("start_file", filename),
    #' @description Pass to each reporter
    #' @param context Context name
    start_context = function(context) private$each("start_context", context),
    #' @description Pass to each reporter
    #' @param context Context name
    #' @param test Test name
    start_test = function(context, test) private$each("start_test", context, test),
    #' @description Pass to each reporter
    #' @param context Context name
    #' @param test Test name
    #' @param result The expectation
    add_result = function(context, test, result) {
      private$each("add_result", context = context, test = test, result = result)
    },
    #' @description Pass to each reporter
    #' @param context Context name
    #' @param test Test name
    end_test = function(context, test) private$each("end_test", context, test),
    #' @description Pass to each reporter
    #' @param context Context name
    end_context = function(context) private$each("end_context", context),
    #' @description Pass to each reporter
    end_reporter = function() private$each("end_reporter"),
    #' @description Pass to each reporter
    end_file = function() private$each("end_file"),
    #' @description Pass to each reporter
    update = function() private$each("update"),

    #' @description Pass to each `CucumberReporter`
    #' @param feature_name Name of the feature
    start_feature = function(feature_name) private$each_cucumber("start_feature", feature_name),
    #' @description Pass to each `CucumberReporter`
    end_feature = function() private$each_cucumber("end_feature"),
    #' @description Pass to each `CucumberReporter`
    #' @param step Pickle step object
    start_step = function(step) private$each_cucumber("start_step", step),
    #' @description Pass to each `CucumberReporter`
    #' @param step Pickle step object with execution results
    end_step = function(step) private$each_cucumber("end_step", step),
    #' @description Pass to each `CucumberReporter`
    #' @param status The hook's status
    #' @param error The hook's error
    end_hook = function(status, error) private$each_cucumber("end_hook", status, error),
    #' @description Pass to each `CucumberReporter`
    #' @param status The scenario's status
    end_scenario = function(status) private$each_cucumber("end_scenario", status),
    #' @description Pass to each `CucumberReporter`
    #' @param envelope A list with one element, named by the message's type
    add_message = function(envelope) private$each_cucumber("add_message", envelope)
  ),
  private = list(
    each = function(method, ...) {
      for (reporter in self$reporters) {
        reporter[[method]](...)
      }
      invisible(self)
    },
    each_cucumber = function(method, ...) {
      for (reporter in self$reporters) {
        cucumber_event(reporter, method, ...)
      }
      invisible(self)
    }
  )
)

#' Cucumber Messages Reporter
#'
#' @description
#' Writes the run as [Cucumber Messages](https://github.com/cucumber/messages):
#' one JSON message per line (NDJSON), like the `message` formatter of other
#' Cucumber implementations. The official tools read it, like the HTML,
#' JUnit and JSON formatters.
#'
#' It reports only the messages. To also see the progress of the run, combine
#' it with another reporter in a [CucumberMultiReporter].
#'
#' The messages follow the protocol version 34.2.1 and are checked with the
#' Cucumber Compatibility Kit. Locations of step definitions and hooks need
#' their source references, kept when the files are sourced with
#' `keep.source = TRUE`, as testthat does.
#'
#' @examples
#' \dontrun{
#' cucumber::test(reporter = cucumber::CucumberMessagesReporter$new("cucumber.ndjson"))
#'
#' # With the progress of the run
#' cucumber::test(reporter = cucumber::CucumberMultiReporter$new(list(
#'   cucumber::CucumberProgressReporter$new(),
#'   cucumber::CucumberMessagesReporter$new("cucumber.ndjson")
#' )))
#' }
#'
#' @export
CucumberMessagesReporter <- R6::R6Class(
  "CucumberMessagesReporter",
  inherit = CucumberReporter,
  public = list(
    #' @field file Path or connection the messages are written to
    file = NULL,

    #' @description
    #' Create a messages reporter
    #' @param file Path of the file to write, replaced by each run, or a
    #'   connection, like `stdout()`. A relative path is relative to the
    #'   working directory when the reporter is created.
    initialize = function(file = "cucumber.ndjson") {
      rlang::check_installed("jsonlite", "to write Cucumber Messages.")
      super$initialize()
      self$file <- if (is.character(file)) as.character(fs::path_abs(file)) else file
    },

    #' @description
    #' Write a message as a line of JSON
    #' @param envelope A list with one element, named by the message's type
    add_message = function(envelope) {
      line <- paste0(envelope_json(envelope), "\n")
      if (is.character(self$file)) {
        # ponytail: the file is opened for each message, keep it open if large runs get slow
        cat(line, file = self$file, append = names(envelope) != "meta")
      } else {
        cat(line, file = self$file)
      }
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
print_error <- function(message, status = "failed") {
  color <- status_color(status)
  # A skip's message already starts with "Reason: "
  label <- switch(status, pending = "Pending: ", skipped = NULL, "Error: ")
  if (!is.null(label)) cat("  ", color(cli::style_bold(label)), "\n", sep = "")
  for (line in strsplit(message, "\n")[[1]]) {
    cat("    ", color(line), "\n", sep = "")
  }
}

print_warning <- function(message) {
  cat("    ", cli::col_yellow(cli::style_italic("Warning: ")), "\n", sep = "")
  for (line in strsplit(message, "\n")[[1]]) {
    cat("      ", cli::col_yellow(line), "\n", sep = "")
  }
}

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

#' Print a step: its status symbol, keyword and text
#'
#' @keywords internal
#' @noRd
print_step <- function(step) {
  cat(
    "    ",
    status_symbol(step$status %||% "passed"),
    " ",
    cli::style_bold(step$keyword),
    " ",
    step$text,
    "\n",
    sep = ""
  )
}

#' Print why a step didn't pass, if it has an error
#'
#' @keywords internal
#' @noRd
print_step_error <- function(step) {
  if (is.null(step$error)) {
    return(invisible())
  }
  color <- status_color(step$status %||% "passed")
  for (line in strsplit(conditionMessage(step$error), "\n")[[1]]) {
    cat("      ", color(line), "\n", sep = "")
  }
}

#' Print a scenario that didn't pass, with its steps and the hooks that didn't pass
#'
#' @keywords internal
#' @noRd
print_failure <- function(failure) {
  cat("\n", bold_label(failure$feature %||% ""), "\n", sep = "")
  cat("  ", bold_label(failure$scenario %||% ""), "\n", sep = "")
  for (step in failure$steps) {
    print_step(step)
    print_step_error(step)
  }
  for (hook in failure$hooks) {
    print_error(conditionMessage(hook$error), hook$status)
  }
}

#' Summary Reporter for Cucumber
#'
#' @description
#' A reporter that prints only the summary of the run, like the `summary`
#' formatter of cucumber-js: the scenarios and steps counted by status, and the
#' scenarios that didn't pass, with their steps and errors.
#'
#' The other cucumber reporters print the same summary at the end of the run:
#' [CucumberProgressReporter], [CucumberProgressBarReporter] and
#' [CucumberPrettyReporter].
#'
#' ```
#' ────────────────────────────────────────────────────────────────────────
#' Summary
#'   2 scenarios (1 failed, 1 passed)
#'   6 steps (1 failed, 5 passed)
#' ────────────────────────────────────────────────────────────────────────
#'
#' Failures
#'
#' Feature: Basket
#'   Scenario: Remove an item
#'     ✔ Given a basket with 2 apples
#'     ✖ When I remove 3 apples
#'       Error: Can't remove more apples than there are.
#' ```
#'
#' @examples
#' \dontrun{
#' cucumber::test("tests/acceptance", reporter = cucumber::CucumberSummaryReporter$new())
#' }
#'
#' @export
CucumberSummaryReporter <- R6::R6Class(
  "CucumberSummaryReporter",
  inherit = CucumberReporter,
  public = list(
    #' @field step_statuses Statuses of the reported steps
    step_statuses = NULL,

    #' @field scenario_statuses Statuses of the finished scenarios
    scenario_statuses = NULL,

    #' @field scenario_failed Whether testthat reported a failure or an error for the current test
    scenario_failed = FALSE,

    #' @field scenario_status Status of the current scenario, once its steps and hooks ran
    scenario_status = NULL,

    #' @field current_scenario Name of the scenario currently executing
    current_scenario = NULL,

    #' @field current_steps Steps executed so far in the current scenario
    current_steps = NULL,

    #' @field current_hooks Results of the current scenario's hooks that failed or are pending
    current_hooks = NULL,

    #' @field step_warnings Warnings of the step currently executing, collected
    #'   when not `NULL`, printed as they happen otherwise
    step_warnings = NULL,

    #' @field failures Recorded failures for the end-of-run summary
    failures = NULL,

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
    #' @param ... Additional arguments passed to parent
    initialize = function(...) {
      super$initialize(...)
      self$step_statuses <- character()
      self$scenario_statuses <- character()
      self$current_steps <- list()
      self$failures <- list()
      # ponytail: capture real color support now, before testthat runs. During a
      # test, output is sunk and cli auto-detects 0 colors; forcing this captured
      # value at each print site re-enables color live while snapshots (built
      # non-interactively -> num_colors = 1) stay plain.
      self$num_colors <- cli::num_ansi_colors()
      # Captured now too: testthat turns them off while it runs a test
      self$unicode <- cli::is_utf8_output()
      self$dynamic <- cli::is_dynamic_tty()
      self$width <- cli::console_width()
      invisible(self)
    },

    #' @description
    #' Draw a line that is redrawn in place, like a progress bar, in a terminal
    #' that can redraw a line
    #' @param text The line
    draw = function(text) {
      self$live <- text
      if (self$dynamic) {
        withr::local_options(cli.num_colors = self$num_colors, cli.unicode = self$unicode)
        text <- cli::ansi_strtrim(text, self$width - 1L)
        cat("\r", text, strrep(" ", max(self$width - 1L - cli::ansi_nchar(text), 0L)), sep = "")
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
      withr::local_options(cli.num_colors = self$num_colors, cli.unicode = self$unicode)
      self$clear()
      force(code)
      if (!is.null(self$live)) self$draw(self$live)
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
    #' Start a test (called by testthat for each scenario)
    #' @param context Test context
    #' @param test Test name (will be "Scenario: `<name>`")
    start_test = function(context, test) {
      if (!is.null(super$start_test)) {
        super$start_test(context, test)
      }
      self$current_scenario <- test
      self$current_steps <- list()
      self$current_hooks <- list()
      self$scenario_status <- NULL
      self$scenario_failed <- FALSE
      invisible(self)
    },

    #' @description
    #' End a test (called by testthat for each scenario). A scenario has the
    #' status given to end_scenario(). A test that isn't a scenario, or one that
    #' stopped before its end, fails if testthat reported a failure or an error.
    #' @param context Test context
    #' @param test Test name
    end_test = function(context, test) {
      if (!is.null(super$end_test)) {
        super$end_test(context, test)
      }
      status <- self$scenario_status %||% (if (self$scenario_failed) "failed" else "passed")
      self$scenario_statuses <- c(self$scenario_statuses, status)
      invisible(self)
    },

    #' @description
    #' Record a scenario's status, and the scenario for the summary if it didn't pass
    #' @param status The scenario's status
    end_scenario = function(status) {
      super$end_scenario(status)
      self$scenario_status <- status
      if (!status %in% c("passed", "skipped")) {
        self$failures <- c(
          self$failures,
          list(list(
            feature = self$current_feature,
            scenario = self$current_scenario,
            steps = self$current_steps,
            hooks = self$current_hooks
          ))
        )
      }
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

      if (inherits(result, c("expectation_error", "expectation_failure"))) {
        self$scenario_failed <- TRUE
      }

      if (inherits(result, "expectation_warning")) {
        if (is.null(self$step_warnings)) {
          self$print_above(print_warning(conditionMessage(result)))
        } else {
          self$step_warnings <- c(self$step_warnings, conditionMessage(result))
        }
      }

      # Display errors that occur outside of a scenario's steps and hooks, e.g.
      # during setup. A scenario's errors are in its summary.
      if (
        is.null(self$scenario_status) &&
          inherits(result, c("expectation_error", "expectation_failure"))
      ) {
        self$print_above(print_error(conditionMessage(result)))
      }

      invisible(self)
    },

    #' @description
    #' Record a scenario's hook that failed, is pending or skipped the scenario
    #' @param status `"failed"`, `"pending"` or `"skipped"`
    #' @param error The hook's error
    end_hook = function(status, error) {
      super$end_hook(status, error)
      self$current_hooks <- c(self$current_hooks, list(list(status = status, error = error)))
      invisible(self)
    },

    #' @description
    #' Record a step's result
    #' @param step Pickle step object with execution results
    end_step = function(step) {
      super$end_step(step)
      self$current_steps <- c(self$current_steps, list(step))
      self$step_statuses <- c(self$step_statuses, step$status %||% "passed")
      invisible(self)
    },

    #' @description
    #' Print the scenarios and steps counted by status
    print_counts = function() {
      withr::local_options(cli.num_colors = self$num_colors, cli.unicode = self$unicode)
      cat("\n")
      cat(cli::rule(), "\n", sep = "")
      cat(cli::style_bold("Summary"), "\n", sep = "")
      cat("  ", format_status_counts(self$scenario_statuses, "scenario"), "\n", sep = "")
      cat("  ", format_status_counts(self$step_statuses, "step"), "\n", sep = "")
      cat(cli::rule(), "\n", sep = "")
      invisible(self)
    },

    #' @description
    #' Print the scenarios that didn't pass
    print_failures = function() {
      withr::local_options(cli.num_colors = self$num_colors, cli.unicode = self$unicode)
      if (length(self$failures) > 0) {
        cat("\n", cli::style_bold("Failures"), "\n", sep = "")
        for (failure in self$failures) {
          print_failure(failure)
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
      self$print_counts()
      self$print_failures()
      invisible(self)
    }
  )
)

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
#' Like the `progress` formatter of cucumber-js, it prints one character for
#' each step and hook as it finishes, then the summary of
#' [CucumberSummaryReporter]:
#'
#' - `.` passed (green)
#' - `F` failed (red)
#' - `-` skipped (cyan)
#' - `P` pending (yellow)
#' - `U` undefined (yellow)
#' - `A` ambiguous (red)
#'
#' ```
#' ......F--
#'
#' ────────────────────────────────────────────────────────────────────────
#' Summary
#'   3 scenarios (1 failed, 2 passed)
#'   9 steps (1 failed, 2 skipped, 6 passed)
#' ────────────────────────────────────────────────────────────────────────
#' ```
#'
#' @examples
#' \dontrun{
#' cucumber::test("tests/acceptance", reporter = cucumber::CucumberDotsReporter$new())
#' }
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
        withr::local_options(cli.num_colors = self$num_colors, cli.unicode = self$unicode)
        status <- tolower(finished$testStepResult$status)
        cat(status_color(status)(DOTS_CHARACTERS[[status]]))
      }
      invisible(self)
    },

    #' @description
    #' End the line of characters and print the summary
    end_reporter = function() {
      cat("\n")
      super$end_reporter()
    }
  )
)

#' A line of the progress reporter: a status, the scenarios counted by status
#' and a name. The header uses the same columns.
#'
#' @keywords internal
#' @noRd
format_progress_line <- function(symbol, cells, name) {
  paste0(symbol, " | ", paste(cells, collapse = " "), " | ", name)
}

#' The cells of a feature's scenarios counted by status. An ambiguous scenario
#' counts as failed, as both are errors.
#'
#' @keywords internal
#' @noRd
progress_cells <- function(statuses) {
  statuses[statuses == "ambiguous"] <- "failed"
  counts <- table(factor(statuses, c("failed", "pending", "undefined", "skipped", "passed")))
  cells <- map2_chr(names(counts), counts, \(status, n) {
    if (status == "passed") sprintf("%3d", n) else if (n == 0) "  " else status_color(status)(sprintf("%2d", n))
  })
  cells
}

#' Progress Reporter for Cucumber
#'
#' @description
#' The default reporter. Like testthat's `ProgressReporter`, it prints one line
#' for each feature, with its scenarios counted by status: failed (`F`),
#' pending (`P`), undefined (`U`), skipped (`S`) and passed (`OK`). An
#' ambiguous scenario counts as failed. While a feature runs, its line is
#' redrawn with a spinner after each step.
#'
#' A scenario that didn't pass is printed as soon as it finishes, with its
#' steps and errors. The summary of [CucumberSummaryReporter] is printed at
#' the end.
#'
#' ```
#'   |  F  P  U  S  OK | Feature
#' ✔ |              3 | Addition
#'
#' Feature: Basket
#'   Scenario: Remove an item
#'     ✔ Given a basket with 2 apples
#'     ✖ When I remove 3 apples
#'       Error: Can't remove more apples than there are.
#' ✖ |  1           2 | Basket [1.2s]
#' ```
#'
#' A feature that took a second or more shows how long it took. The line is
#' redrawn only in a terminal that can redraw a line, see
#' [cli::is_dynamic_tty()]. Elsewhere, like in CI, each feature's line is
#' printed once it finishes.
#'
#' To see each step, use [CucumberPrettyReporter].
#'
#' @examples
#' \dontrun{
#' cucumber::test("tests/acceptance", reporter = cucumber::CucumberProgressReporter$new())
#' }
#'
#' @export
CucumberProgressReporter <- R6::R6Class(
  "CucumberProgressReporter",
  inherit = CucumberSummaryReporter,
  public = list(
    #' @field header_printed Whether the header of the columns was printed
    header_printed = FALSE,

    #' @field feature_first Index of the current feature's first scenario in `scenario_statuses`
    feature_first = 1L,

    #' @field feature_start When the current feature started
    feature_start = NULL,

    #' @field frames Frames of the spinner, captured at construction
    frames = NULL,

    #' @field frame Number of steps of the current feature finished, to turn the spinner
    frame = 0L,

    #' @description
    #' Initialize the reporter
    #' @param ... Additional arguments passed to parent
    initialize = function(...) {
      super$initialize(...)
      self$frames <- cli::get_spinner()$frames
      invisible(self)
    },

    #' @description
    #' Print the header once, and start the feature's line
    #' @param feature_name Name of the feature
    start_feature = function(feature_name) {
      super$start_feature(feature_name)
      withr::local_options(cli.num_colors = self$num_colors, cli.unicode = self$unicode)
      if (!self$header_printed) {
        cat(format_progress_line(" ", sprintf(c("%2s", "%2s", "%2s", "%2s", "%3s"), c("F", "P", "U", "S", "OK")), "Feature"), "\n", sep = "")
        self$header_printed <- TRUE
      }
      self$feature_first <- length(self$scenario_statuses) + 1L
      self$feature_start <- Sys.time()
      self$frame <- 0L
      self$draw_feature()
    },

    #' @description
    #' Turn the spinner after a step
    #' @param step Pickle step object with execution results
    end_step = function(step) {
      super$end_step(step)
      self$frame <- self$frame + 1L
      self$draw_feature()
    },

    #' @description
    #' Count the scenario in the feature's line
    #' @param context Test context
    #' @param test Test name
    end_test = function(context, test) {
      super$end_test(context, test)
      if (!is.null(self$live)) self$draw_feature()
      invisible(self)
    },

    #' @description
    #' Print the scenario if it didn't pass
    #' @param status The scenario's status
    end_scenario = function(status) {
      n <- length(self$failures)
      super$end_scenario(status)
      self$print_failures_since(n)
    },

    #' @description
    #' Print the feature's final line, with its status and how long it took
    end_feature = function() {
      withr::local_options(cli.num_colors = self$num_colors, cli.unicode = self$unicode)
      statuses <- self$feature_statuses()
      self$clear()
      self$live <- NULL
      if (length(statuses) > 0) {
        worst <- STEP_STATUSES[min(match(statuses, STEP_STATUSES))]
        line <- self$feature_line(status_symbol(worst))
        time <- as.numeric(difftime(Sys.time(), self$feature_start, units = "secs"))
        if (time >= 1) line <- paste0(line, cli::col_grey(sprintf(" [%.1fs]", time)))
        cat(line, "\n", sep = "")
      }
      super$end_feature()
    },

    #' @description
    #' Statuses of the current feature's finished scenarios
    feature_statuses = function() {
      self$scenario_statuses[seq_along(self$scenario_statuses) >= self$feature_first]
    },

    #' @description
    #' The current feature's line
    #' @param symbol The status column
    feature_line = function(symbol) {
      format_progress_line(
        symbol,
        progress_cells(self$feature_statuses()),
        sub("^[^:]*:\\s*", "", self$current_feature %||% "")
      )
    },

    #' @description
    #' Draw the current feature's line with the spinner
    draw_feature = function() {
      withr::local_options(cli.num_colors = self$num_colors, cli.unicode = self$unicode)
      self$draw(self$feature_line(self$frames[[self$frame %% length(self$frames) + 1L]]))
    }
  )
)

#' Progress Bar Reporter for Cucumber
#'
#' @description
#' Like the `progress-bar` formatter of cucumber-js, it shows a bar of the
#' steps and hooks run so far, redrawn in place. A scenario that didn't pass is
#' printed above the bar as soon as it finishes, with its steps and errors. The
#' scenarios and steps counted by status are printed at the end.
#'
#' ```
#' Feature: Basket
#'   Scenario: Remove an item
#'     ✔ Given a basket with 2 apples
#'     ✖ When I remove 3 apples
#'       Error: Can't remove more apples than there are.
#' 12/40 steps [==============                                         ]
#' ```
#'
#' The bar is drawn only in a terminal that can redraw a line, see
#' [cli::is_dynamic_tty()]. Elsewhere, like in CI, only the scenarios that
#' didn't pass and the summary are printed.
#'
#' @examples
#' \dontrun{
#' cucumber::test("tests/acceptance", reporter = cucumber::CucumberProgressBarReporter$new())
#' }
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
    #' Print a scenario that didn't pass above the bar
    #' @param status The scenario's status
    end_scenario = function(status) {
      n <- length(self$failures)
      super$end_scenario(status)
      self$print_failures_since(n)
    },

    #' @description
    #' Draw the bar
    draw_bar = function() {
      label <- sprintf("%d/%d steps ", self$current, self$total)
      size <- max(self$width - nchar(label) - 3L, 10L)
      done <- round(size * min(self$current / max(self$total, 1L), 1))
      self$draw(paste0(label, "[", strrep("=", done), strrep(" ", size - done), "]"))
    },

    #' @description
    #' Clear the bar and print the scenarios and steps counted by status. The
    #' scenarios that didn't pass were printed when they finished.
    end_reporter = function() {
      self$clear()
      self$live <- NULL
      self$print_counts()
      invisible(self)
    }
  )
)

#' Pretty Reporter for Cucumber
#'
#' @description
#' A reporter that prints each feature, scenario and step as it runs, like the
#' `pretty` formatter of cucumber-js, then the summary of
#' [CucumberSummaryReporter].
#'
#' @details
#' Prints each step as it executes with a status indicator, grouped under
#' scenario and feature headers:
#'
#' - \ifelse{latex}{[x]}{✓} for passed steps (green)
#' - \ifelse{latex}{[ ]}{✗} for failed steps (red)
#' - `-` for skipped steps (cyan)
#' - `P` for pending steps (yellow)
#' - `U` for undefined steps (yellow)
#' - `A` for ambiguous steps (red)
#'
#' A step's Doc String or Data Table and the warnings it raised are printed
#' under it.
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
#' cucumber::test("tests/acceptance", reporter = cucumber::CucumberPrettyReporter$new())
#'
#' # testthat reporters still work, reporting at the scenario level only
#' cucumber::test("tests/acceptance", reporter = testthat::ProgressReporter$new())
#'
#' # Silent mode
#' cucumber::test("tests/acceptance", reporter = testthat::SilentReporter$new())
#'
#' # From within a test file
#' cucumber::run(reporter = cucumber::CucumberPrettyReporter$new())
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
#' cucumber::test(
#'   "tests/acceptance",
#'   reporter = cucumber::CucumberPrettyReporter$new()
#' )
#' }
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
      invisible(self)
    },

    #' @description
    #' Start a feature
    #' @param feature_name Name of the feature
    start_feature = function(feature_name) {
      super$start_feature(feature_name)
      withr::local_options(cli.num_colors = self$num_colors, cli.unicode = self$unicode)
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
      super$start_test(context, test)
      withr::local_options(cli.num_colors = self$num_colors, cli.unicode = self$unicode)
      cat("  ", bold_label(test), "\n", sep = "")
      invisible(self)
    },

    #' @description
    #' Print the error of a scenario's hook that failed or is pending, or the
    #' reason of one that skipped the scenario
    #' @param status `"failed"`, `"pending"` or `"skipped"`
    #' @param error The hook's error
    end_hook = function(status, error) {
      super$end_hook(status, error)
      withr::local_options(cli.num_colors = self$num_colors, cli.unicode = self$unicode)
      print_error(conditionMessage(error), status)
      invisible(self)
    },

    #' @description
    #' Start a step
    #' @param step Pickle step object
    start_step = function(step) {
      super$start_step(step)
      self$step_warnings <- character()
      invisible(self)
    },

    #' @description
    #' End a step and print its result
    #' @param step Pickle step object with execution results
    end_step = function(step) {
      super$end_step(step)

      withr::local_options(cli.num_colors = self$num_colors, cli.unicode = self$unicode)

      # ponytail: cat to stdout so expect_snapshot can capture step output; color
      # is re-enabled via the num_colors option forced above.
      print_step(step)

      self$print_step_args(step)

      for (warning in self$step_warnings) {
        print_warning(warning)
      }
      self$step_warnings <- NULL

      print_step_error(step)

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

#' Cucumber Reporter Base Class
#'
#' @description
#' Base class for cucumber reporters. Extend it to report a run your way,
#' overriding the methods you need. Each does nothing by default.
#'
#' @section Methods:
#' \describe{
#'   \item{`start_run()`}{Called when a run starts}
#'   \item{`end_run(error)`}{Called when a run ends, with the error that stopped it, like a failing `before_all()` hook, or `NULL`}
#'   \item{`add_message(envelope)`}{Called with each Cucumber Message of the run, see [CucumberMessagesReporter]}
#'   \item{`add_warning(warning)`}{Called with each warning raised in a step, a hook or elsewhere in the run}
#'   \item{`report(file)`}{Reports a run after it ran, from the Cucumber Messages [CucumberMessagesReporter] stored in `file`}
#' }
#'
#' An envelope is a list with one element, named by the message's type. The
#' messages of a scenario are, in order:
#'
#' - `testCaseStarted`, with the `id` its other messages refer to and the
#'   `testCaseId` of its `testCase`, sent before the run starts, whose
#'   `pickleId` is the id of its `pickle`: the scenario's name, tags and steps.
#' - `testStepStarted` and `testStepFinished` of each hook and step, with the
#'   `testStepResult`: its `status`, like `"PASSED"`, `duration` and the
#'   `message` of its error.
#' - `testCaseFinished`.
#'
#' Combine reporters with [CucumberMultiReporter].
#'
#' @examples
#' \dontrun{
#' # Count the steps and hooks by status
#' StatusReporter <- R6::R6Class(
#'   "StatusReporter",
#'   inherit = cucumber::CucumberReporter,
#'   public = list(
#'     statuses = character(),
#'     add_message = function(envelope) {
#'       finished <- envelope$testStepFinished
#'       if (!is.null(finished)) {
#'         self$statuses <- c(self$statuses, finished$testStepResult$status)
#'       }
#'     },
#'     end_run = function(error = NULL) {
#'       print(table(self$statuses))
#'     }
#'   )
#' )
#' cucumber::test("tests/acceptance", reporter = StatusReporter$new())
#' }
#'
#' @eval features_rd(features = "r-custom_reporter.feature")
#'
#' @importFrom R6 R6Class
#' @importFrom rlang %||%
#' @importFrom purrr map2_chr
#' @keywords internal
#' @export
CucumberReporter <- R6::R6Class(
  "CucumberReporter",
  public = list(
    #' @description
    #' Start a run
    start_run = function() {
      invisible(self)
    },

    #' @description
    #' End a run
    #' @param error The error that stopped the run, or `NULL`
    end_run = function(error = NULL) {
      invisible(self)
    },

    #' @description
    #' Called with each warning raised in a step, a hook or elsewhere in the run
    #' @param warning The warning
    add_warning = function(warning) {
      invisible(self)
    },

    #' @description
    #' Called with each Cucumber Message of the run
    #' @param envelope A list with one element, named by the message's type,
    #'   like `list(testCaseStarted = list(...))`
    add_message = function(envelope) {
      invisible(self)
    },

    #' @description
    #' Report a run after it ran: send this reporter the Cucumber Messages
    #' stored in a file, like a run reports them
    #' @param file Path of the NDJSON file a [CucumberMessagesReporter] wrote
    report = function(file) {
      rlang::check_installed("jsonlite", "to read Cucumber Messages.")
      lines <- readLines(file, warn = FALSE, encoding = "UTF-8")
      self$start_run()
      for (line in lines[nzchar(lines)]) {
        self$add_message(jsonlite::fromJSON(line, simplifyVector = FALSE))
      }
      self$end_run()
      invisible(self)
    }
  )
)

#' Call a cucumber event on a reporter, if there is one. An error of the
#' reporter stops the run, naming the reporter and the event.
#' @keywords internal
#' @noRd
cucumber_event <- function(reporter, method, ...) {
  if (is.null(reporter)) {
    return(invisible())
  }
  tryCatch(
    reporter[[method]](...),
    error = function(e) {
      # Of a reporter in a CucumberMultiReporter, already named
      if (!inherits(e, "cucumber_reporter_error")) {
        # The call would be cucumber's call of the method
        e$call <- NULL
        e <- rlang::error_cnd(
          class = "cucumber_reporter_error",
          message = glue::glue("Reporter `{class(reporter)[[1]]}` failed in `{method}()`."),
          parent = e,
          trace = empty_trace()
        )
      }
      abort_run(e)
    }
  )
  invisible()
}

#' Check that a reporter is a CucumberReporter, or NULL for no reporter
#' @keywords internal
#' @noRd
check_reporter <- function(reporter, call = rlang::caller_env()) {
  if (!is.null(reporter) && !inherits(reporter, "CucumberReporter")) {
    rlang::abort(
      c(
        "`reporter` must be a `CucumberReporter`, or `NULL` to report nothing.",
        i = "testthat reporters can't report a cucumber run, use one of cucumber's, like `CucumberProgressReporter$new()`."
      ),
      call = call
    )
  }
  invisible(reporter)
}

#' Combine reporters
#'
#' @description
#' Passes every event to each of its reporters. Use it, for example, to print
#' the progress of a run and write its messages.
#'
#' @examples
#' \dontrun{
#' cucumber::test(reporter = cucumber::CucumberMultiReporter$new(list(
#'   cucumber::CucumberProgressReporter$new(),
#'   cucumber::CucumberMessagesReporter$new("cucumber.ndjson")
#' )))
#' }
#'
#' @eval features_rd(features = "r-reporters.feature")
#'
#' @export
CucumberMultiReporter <- R6::R6Class(
  "CucumberMultiReporter",
  inherit = CucumberReporter,
  public = list(
    #' @field reporters The reporters to pass the events to
    reporters = list(),

    #' @description
    #' Combine reporters
    #' @param reporters A list of `CucumberReporter`s
    initialize = function(reporters = list()) {
      lapply(reporters, check_reporter)
      self$reporters <- reporters
    },

    #' @description Pass to each reporter
    start_run = function() private$each("start_run"),
    #' @description Pass to each reporter
    #' @param error The error that stopped the run, or `NULL`
    end_run = function(error = NULL) private$each("end_run", error),
    #' @description Pass to each reporter
    #' @param warning The warning
    add_warning = function(warning) private$each("add_warning", warning),
    #' @description Pass to each reporter
    #' @param envelope A list with one element, named by the message's type
    add_message = function(envelope) private$each("add_message", envelope)
  ),
  private = list(
    each = function(method, ...) {
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
#' Writes the run as [Cucumber Messages](https://github.com/cucumber/messages).
#' To also see the progress of the run, combine it with another reporter in a
#' [CucumberMultiReporter].
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
#' @eval features_rd(features = "r-messages_reporter.feature")
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

#' Render a data table's rows as aligned Gherkin pipe rows
#'
#' @param rows List of character vectors, one per row, the first one being the header
#' @keywords internal
#' @noRd
format_data_table <- function(rows) {
  cells <- do.call(rbind, rows)
  widths <- apply(cells, 2, \(col) max(nchar(col)))
  apply(cells, 1, \(row) {
    padded <- mapply(
      \(cell, w) formatC(cell, width = w, flag = "-"),
      row,
      widths
    )
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
  for (line in strsplit(step$error, "\n")[[1]]) {
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
    print_error(hook$error, hook$status)
  }
}

#' The lines an attachment is printed as: the text of a log or the links,
#' or the media type and file name of other data
#'
#' @keywords internal
#' @noRd
format_attachment <- function(attachment) {
  if (
    attachment$mediaType %in% c("text/x.cucumber.log+plain", "text/uri-list")
  ) {
    return(strsplit(attachment$body, "\n", fixed = TRUE)[[1]])
  }
  paste0(
    "Attachment (",
    attachment$mediaType,
    ")",
    if (!is.null(attachment$fileName)) paste0(": ", attachment$fileName)
  )
}

#' A pickle step and its result, as the reporters print it: its keyword as
#' written, text, status, error message, and the lines of its Doc String or
#' the rows of its Data Table
#'
#' @keywords internal
#' @noRd
reported_step <- function(q, pickle_step, result) {
  argument <- pickle_step$argument
  list(
    keyword = trimws(q$step_of(pickle_step)$keyword),
    text = pickle_step$text,
    status = tolower(result$status),
    error = result$message,
    docstring = if (!is.null(argument$docString)) {
      strsplit(argument$docString$content, "\n", fixed = TRUE)[[1]]
    },
    data_table = if (!is.null(argument$dataTable)) {
      lapply(argument$dataTable$rows, \(row) {
        vapply(row$cells, \(cell) cell$value, character(1))
      })
    }
  )
}

#' Summary Reporter for Cucumber
#'
#' @description
#' Prints only the summary of the run. The other cucumber reporters print it at
#' the end of the run too:
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
#' @eval features_rd(features = "r-summary_reporter.feature")
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

    #' @field current_feature Name of the feature currently executing, like `"Feature: Basket"`
    current_feature = NULL,

    #' @field current_scenario Name of the scenario currently executing, like `"Scenario: Add an item"`
    current_scenario = NULL,

    #' @field current_steps Steps executed so far in the current scenario
    current_steps = NULL,

    #' @field current_hooks Results of the current scenario's hooks that failed, are pending or skipped it
    current_hooks = NULL,

    #' @field failures Recorded failures for the end-of-run summary
    failures = NULL,

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
    initialize = function() {
      self$step_statuses <- character()
      self$scenario_statuses <- character()
      self$current_steps <- list()
      self$failures <- list()
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
      invisible(self)
    },

    #' @description
    #' Draw a line that is redrawn in place, like a progress bar, in a terminal
    #' that can redraw a line
    #' @param text The line
    draw = function(text) {
      self$live <- text
      if (self$dynamic) {
        withr::local_options(
          cli.num_colors = self$num_colors,
          cli.unicode = self$unicode
        )
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
      withr::local_options(
        cli.num_colors = self$num_colors,
        cli.unicode = self$unicode
      )
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
      q$update(envelope)
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
            self$current_feature <- paste0(
              lineage$feature$keyword,
              ": ",
              lineage$feature$name
            )
            private$on_feature_start()
          }
          self$current_scenario <- paste0(
            lineage$scenario$keyword,
            ": ",
            pickle$name,
            if (message$attempt > 0) paste0(" (attempt ", message$attempt + 1, ")")
          )
          private$steps_before <- length(self$step_statuses)
          self$current_steps <- list()
          self$current_hooks <- list()
          private$on_scenario_start()
        },
        testStepStarted = {
          if (!is.null(q$test_steps[[message$testStepId]]$pickleStepId)) {
            private$on_step_start()
          }
        },
        testStepFinished = {
          test_step <- q$test_steps[[message$testStepId]]
          result <- message$testStepResult
          if (!is.null(test_step$pickleStepId)) {
            step <- reported_step(
              q,
              q$pickle_steps[[test_step$pickleStepId]],
              result
            )
            self$current_steps <- c(self$current_steps, list(step))
            self$step_statuses <- c(self$step_statuses, step$status)
            private$on_step_end(step)
          } else if (!is.null(result$message)) {
            hook <- list(
              status = tolower(result$status),
              error = result$message
            )
            self$current_hooks <- c(self$current_hooks, list(hook))
            private$on_hook_end(hook)
          }
        },
        testCaseFinished = {
          # Only the last attempt of a scenario is counted
          if (isTRUE(message$willBeRetried)) {
            self$step_statuses <- self$step_statuses[seq_len(private$steps_before)]
            return(invisible(self))
          }
          started <- q$test_cases_started[[message$testCaseStartedId]]
          status <- tolower(
            q$most_severe_result_of(started)$status %||% "PASSED"
          )
          self$scenario_statuses <- c(self$scenario_statuses, status)
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
          private$on_scenario_end(status)
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
      withr::local_options(
        cli.num_colors = self$num_colors,
        cli.unicode = self$unicode
      )
      # Like cucumber-js, the last step definition that used each one
      types <- self$undefined_parameter_types
      if (length(types) > 0) {
        cat("\n", cli::col_yellow("Undefined parameter types:"), "\n", sep = "")
        cat(sprintf("- \"%s\" e.g. `%s`\n", names(types), types), sep = "")
      }
      cat("\n")
      cat(cli::rule(), "\n", sep = "")
      cat(cli::style_bold("Summary"), "\n", sep = "")
      cat(
        "  ",
        format_status_counts(self$scenario_statuses, "scenario"),
        "\n",
        sep = ""
      )
      cat(
        "  ",
        format_status_counts(self$step_statuses, "step"),
        "\n",
        sep = ""
      )
      cat(cli::rule(), "\n", sep = "")
      invisible(self)
    },

    #' @description
    #' Print the scenarios that didn't pass
    print_failures = function() {
      withr::local_options(
        cli.num_colors = self$num_colors,
        cli.unicode = self$unicode
      )
      if (length(self$failures) > 0) {
        cat("\n", cli::style_bold("Failures"), "\n", sep = "")
        for (failure in self$failures) {
          print_failure(failure)
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
      self$print_counts()
      self$print_failures()
      invisible(self)
    }
  ),
  private = list(
    query = NULL,
    feature_uri = NULL,
    # Number of steps counted before the current attempt of a scenario
    steps_before = 0L,

    finish_feature = function() {
      if (!is.null(private$feature_uri)) {
        private$on_feature_end()
        private$feature_uri <- NULL
        self$current_feature <- NULL
      }
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
        withr::local_options(cli.num_colors = self$num_colors, cli.unicode = self$unicode)
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
#' The default reporter. Prints one line for each feature, with its scenarios
#' counted by status, then the summary of [CucumberSummaryReporter]:
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
#' To see each step, use [CucumberPrettyReporter].
#'
#' @examples
#' \dontrun{
#' cucumber::test("tests/acceptance", reporter = cucumber::CucumberProgressReporter$new())
#' }
#'
#' @eval features_rd(features = "r-progress_reporter.feature")
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
    initialize = function() {
      super$initialize()
      self$frames <- cli::get_spinner()$frames
      invisible(self)
    },

    #' @description
    #' Statuses of the current feature's finished scenarios
    feature_statuses = function() {
      self$scenario_statuses[
        seq_along(self$scenario_statuses) >= self$feature_first
      ]
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
      withr::local_options(
        cli.num_colors = self$num_colors,
        cli.unicode = self$unicode
      )
      self$draw(self$feature_line(self$frames[[
        self$frame %% length(self$frames) + 1L
      ]]))
    }
  ),
  private = list(
    # Print the header once, and start the feature's line
    on_feature_start = function() {
      withr::local_options(
        cli.num_colors = self$num_colors,
        cli.unicode = self$unicode
      )
      if (!self$header_printed) {
        cat(
          format_progress_line(
            " ",
            sprintf(
              c("%2s", "%2s", "%2s", "%2s", "%3s"),
              c("F", "P", "U", "S", "OK")
            ),
            "Feature"
          ),
          "\n",
          sep = ""
        )
        self$header_printed <- TRUE
      }
      self$feature_first <- length(self$scenario_statuses) + 1L
      self$feature_start <- Sys.time()
      self$frame <- 0L
      self$draw_feature()
    },

    # Turn the spinner after a step
    on_step_end = function(step) {
      self$frame <- self$frame + 1L
      self$draw_feature()
    },

    # Count the scenario in the feature's line, and print it if it didn't pass
    on_scenario_end = function(status) {
      failed <- !status %in% c("passed", "skipped")
      self$print_failures_since(length(self$failures) - failed)
      self$draw_feature()
    },

    # Print the feature's final line, with its status and how long it took
    on_feature_end = function() {
      withr::local_options(
        cli.num_colors = self$num_colors,
        cli.unicode = self$unicode
      )
      statuses <- self$feature_statuses()
      self$clear()
      self$live <- NULL
      if (length(statuses) > 0) {
        worst <- STEP_STATUSES[min(match(statuses, STEP_STATUSES))]
        line <- self$feature_line(status_symbol(worst))
        time <- as.numeric(difftime(
          Sys.time(),
          self$feature_start,
          units = "secs"
        ))
        if (time >= 1) {
          line <- paste0(line, cli::col_grey(sprintf(" [%.1fs]", time)))
        }
        cat(line, "\n", sep = "")
      }
    }
  )
)

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
#'       Error: Can't remove more apples than there are.
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

    #' @description
    #' Initialize the reporter
    #' @param show_praise Whether to show praise (default TRUE)
    #' @param reporter_max_docstring_lines Max docstring lines to print for a step before
    #'   truncating. Defaults to the `cucumber.reporter_max_docstring_lines` option, or
    #'   `Inf` (print in full) if unset.
    #' @param reporter_max_table_lines Max data table rows to print for a step before
    #'   truncating. Defaults to the `cucumber.reporter_max_table_lines` option, or `Inf`
    #'   (print in full) if unset.
    initialize = function(
      show_praise = TRUE,
      reporter_max_docstring_lines = getOption(
        "cucumber.reporter_max_docstring_lines",
        Inf
      ),
      reporter_max_table_lines = getOption(
        "cucumber.reporter_max_table_lines",
        Inf
      )
    ) {
      super$initialize()
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
    #' Print a step's docstring and/or data table arguments, indented and
    #' truncated to `reporter_max_docstring_lines` / `reporter_max_table_lines`
    #' @param step The step, with its `docstring` lines or `data_table` rows
    print_step_args = function(step) {
      if (!is.null(step$docstring)) {
        body <- truncate_lines(
          step$docstring,
          self$reporter_max_docstring_lines
        )
        for (line in c('"""', body, '"""')) {
          cat("      ", cli::style_dim(line), "\n", sep = "")
        }
      }
      if (!is.null(step$data_table)) {
        rows <- format_data_table(step$data_table)
        # Keep the header, truncate only the body rows
        rows <- c(
          rows[1],
          truncate_lines(rows[-1], self$reporter_max_table_lines)
        )
        for (line in rows) {
          cat("      ", cli::style_dim(line), "\n", sep = "")
        }
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
    },

    on_feature_end = function() {
      cat("\n")
    },

    on_scenario_start = function() {
      withr::local_options(
        cli.num_colors = self$num_colors,
        cli.unicode = self$unicode
      )
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

#' Get reporter from options
#'
#' @keywords internal
#' @noRd
get_reporter <- function() {
  getOption(".cucumber_reporter", default = CucumberProgressReporter$new())
}

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

    #' @field step_warnings Warnings of the step currently executing, printed when it ends
    step_warnings = NULL,

    #' @field failures Recorded failures for the end-of-run summary
    failures = NULL,

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
      self$current_hooks <- list()
      self$scenario_status <- NULL
      self$scenario_failed <- FALSE
      withr::local_options(cli.num_colors = self$num_colors)
      cat("  ", bold_label(test), "\n", sep = "")
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

      withr::local_options(cli.num_colors = self$num_colors)

      if (inherits(result, c("expectation_error", "expectation_failure"))) {
        self$scenario_failed <- TRUE
      }

      # A step's warnings are printed by end_step, under the step
      if (inherits(result, "expectation_warning")) {
        if (is.null(self$step_warnings)) {
          print_warning(conditionMessage(result))
        } else {
          self$step_warnings <- c(self$step_warnings, conditionMessage(result))
        }
      }

      # Display errors that occur outside of a scenario's steps and hooks, e.g.
      # during setup. A scenario's errors were printed by end_step and end_hook.
      if (
        is.null(self$scenario_status) &&
          inherits(result, c("expectation_error", "expectation_failure"))
      ) {
        print_error(conditionMessage(result))
      }

      invisible(self)
    },

    #' @description
    #' Print the error of a scenario's hook that failed or is pending, or the
    #' reason of one that skipped the scenario
    #' @param status `"failed"`, `"pending"` or `"skipped"`
    #' @param error The hook's error
    end_hook = function(status, error) {
      super$end_hook(status, error)
      self$current_hooks <- c(self$current_hooks, list(list(status = status, error = error)))
      withr::local_options(cli.num_colors = self$num_colors)
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

      withr::local_options(cli.num_colors = self$num_colors)

      self$current_steps <- c(self$current_steps, list(step))

      status <- step$status %||% "passed"
      self$step_statuses <- c(self$step_statuses, status)

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

      for (warning in self$step_warnings) {
        print_warning(warning)
      }
      self$step_warnings <- NULL

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
          for (hook in failure$hooks) {
            print_error(conditionMessage(hook$error), hook$status)
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

#' Cucumber Reporter Base Class
#'
#' @description
#' Base class for cucumber reporters. Extend it to report a run your way,
#' overriding the methods you need. Each does nothing by default.
#'
#' @section Methods:
#' \describe{
#'   \item{`start_run()`}{Called when a run starts}
#'   \item{`end_run(error)`}{Called when a run ends, with the error that stopped it, like a
#'     failing `before_all()` hook, or `NULL`}
#'   \item{`add_message(envelope)`}{Called with each Cucumber Message of the run, see [CucumberMessagesReporter]}
#'   \item{`add_warning(warning)`}{Called with each warning raised in a step, a hook or elsewhere in the run}
#'   \item{`report(file)`}{Reports a run after it ran, from the Cucumber Messages
#'     [CucumberMessagesReporter] stored in `file`}
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
    #' @field output Path of the file what the reporter prints goes to, replaced
    #'   by each run, or `NULL` to print to the console
    output = NULL,

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
      reporter_call(self, "start_run")
      for (line in lines[nzchar(lines)]) {
        reporter_call(self, "add_message", jsonlite::fromJSON(line, simplifyVector = FALSE))
      }
      reporter_call(self, "end_run")
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
    reporter_call(reporter, method, ...),
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
      stop_with_restart("cucumber_abort_run", e)
    }
  )
  invisible()
}

#' Call an event of a reporter, with what it prints going to its `output`
#' file, if it has one, which the start of a run replaces
#' @keywords internal
#' @noRd
reporter_call <- function(reporter, method, ...) {
  if (is.null(reporter$output)) {
    return(reporter[[method]](...))
  }
  withr::with_output_sink(reporter$output, append = method != "start_run", reporter[[method]](...))
}

#' Check that a reporter is a CucumberReporter, or NULL for no reporter
#' @keywords internal
#' @noRd
check_reporter <- function(reporter, call = rlang::caller_env(), arg = "reporter") {
  if (!is.null(reporter) && !inherits(reporter, "CucumberReporter")) {
    rlang::abort(
      c(
        paste0("`", arg, "` must be a `CucumberReporter`, or `NULL` to report nothing."),
        i = paste(
          "testthat reporters can't report a cucumber run,",
          "use one of cucumber's, like `CucumberProgressReporter$new()`."
        )
      ),
      call = call
    )
  }
  invisible(reporter)
}

#' The absolute path of a report's file, with its directory created, like
#' Cucumber creates the directories of a formatter's file
#' @keywords internal
#' @noRd
report_path <- function(file) {
  file <- as.character(fs::path_abs(file))
  fs::dir_create(fs::path_dir(file))
  file
}

#' A feature's keyword and name, like `"Feature: Basket"`. A Markdown
#' document's Feature can have no keyword, then it's its name.
#' @keywords internal
#' @noRd
feature_label <- function(feature) {
  if (is.null(feature$keyword)) feature$name else paste0(feature$keyword, ": ", feature$name)
}

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

#' Render a data table's rows as aligned Gherkin pipe rows, with their cells
#' escaped as they are written
#'
#' @param rows List of character vectors, one per row, the first one being the header
#' @keywords internal
#' @noRd
format_data_table <- function(rows) {
  escape <- \(x) gsub("\n", "\\n", gsub("|", "\\|", gsub("\\", "\\\\", x, fixed = TRUE), fixed = TRUE), fixed = TRUE)
  cells <- do.call(rbind, lapply(rows, escape))
  widths <- apply(cells, 2, \(col) max(nchar(col)))
  apply(cells, 1, \(row) {
    # Not formatC(), which counts a backslash as two characters
    padded <- paste0(row, strrep(" ", widths - nchar(row)))
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

#' Print the error of a hook or of the run, labelled by its status
#'
#' @keywords internal
#' @noRd
print_error <- function(message, status = "failed") {
  # A skip's message already starts with "Reason: "
  label <- switch(status, pending = "Pending: ", skipped = NULL, "Error: ")
  print_block(if (!is.null(label)) cli::style_bold(label), message, status_color(status), "  ")
}

print_warning <- function(message) {
  print_block(cli::style_italic("Warning: "), message, cli::col_yellow, "    ")
}

#' Print `label`, if any, at `indent`, then each line of `message` indented under it
#' @keywords internal
#' @noRd
print_block <- function(label, message, color, indent) {
  if (!is.null(label)) cat(indent, color(label), "\n", sep = "")
  for (line in strsplit(message, "\n")[[1]]) {
    cat(indent, "  ", color(line), "\n", sep = "")
  }
}

# Order of step statuses from the worst to the best, as in Cucumber summaries
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

#' A duration in milliseconds, like `0m01.234s`
#'
#' @keywords internal
#' @noRd
format_duration <- function(millis) {
  millis <- floor(millis)
  sprintf("%dm%02d.%03ds", millis %/% 60000, (millis %/% 1000) %% 60, millis %% 1000)
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
  # Messages of pending, undefined and skipped steps say what they are
  label <- if (step$status %in% c("failed", "ambiguous")) cli::style_bold("Error: ")
  print_block(label, step$error, status_color(step$status %||% "passed"), "    ")
}

#' Print a scenario that didn't pass, with its steps and the hooks that didn't pass
#'
#' @param number Its number in the summary, which shows where the scenario is
#'   instead of its feature
#' @keywords internal
#' @noRd
print_failure <- function(failure, number = NULL) {
  if (is.null(number)) {
    cat("\n", bold_label(failure$feature %||% ""), "\n", sep = "")
    cat("  ", bold_label(failure$scenario %||% ""), "\n", sep = "")
  } else {
    location <- cli::col_grey(paste0(" # ", failure$location))
    cat("\n", number, ") ", bold_label(failure$scenario), location, "\n", sep = "")
  }
  # Each hook is printed where it ran, after the steps before it
  print_hooks <- function(steps) {
    for (hook in Filter(\(hook) hook$after_steps == steps, failure$hooks)) {
      print_error(hook$error, hook$status)
    }
  }
  print_hooks(0)
  for (i in seq_along(failure$steps)) {
    print_step(failure$steps[[i]])
    print_step_error(failure$steps[[i]])
    print_hooks(i)
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

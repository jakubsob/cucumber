#' Cucumber JUnit Reporter
#'
#' @description
#' Writes the run as a JUnit XML report, the one of the official Cucumber
#' JUnit XML formatter (<https://github.com/cucumber/junit-xml-formatter>),
#' for CI services like Jenkins, GitHub Actions or GitLab. To also see the
#' progress of the run, combine it with another reporter in a
#' [CucumberMultiReporter]. To write the report of a run after it ran, store
#' its messages with [CucumberMessagesReporter] and pass their file to
#' `report()`.
#'
#' @examples
#' \dontrun{
#' cucumber::test(reporter = cucumber::CucumberJunitReporter$new("cucumber-junit.xml"))
#'
#' # With the progress of the run
#' cucumber::test(reporter = cucumber::CucumberMultiReporter$new(list(
#'   cucumber::CucumberProgressReporter$new(),
#'   cucumber::CucumberJunitReporter$new("cucumber-junit.xml")
#' )))
#'
#' # From the messages of a run, after it ran
#' cucumber::test(reporter = cucumber::CucumberMessagesReporter$new("cucumber.ndjson"))
#' cucumber::CucumberJunitReporter$new("cucumber-junit.xml")$report("cucumber.ndjson")
#' }
#'
#' @eval features_rd(features = "r-junit_reporter.feature")
#'
#' @export
CucumberJunitReporter <- R6::R6Class(
  "CucumberJunitReporter",
  inherit = CucumberQueryReporter,
  public = list(
    #' @field file Path of the XML file the report is written to
    file = NULL,

    #' @description
    #' Create a JUnit reporter
    #' @param file Path of the XML file to write, replaced by each run. A
    #'   relative path is relative to the working directory when the reporter
    #'   is created. Its directory is created when the reporter is, if it
    #'   doesn't exist.
    initialize = function(file = "cucumber-junit.xml") {
      self$file <- report_path(file)
    },

    #' @description
    #' Write the report
    #' @param error The error that stopped the run, or `NULL`
    end_run = function(error = NULL) {
      writeLines(enc2utf8(junit_xml(private$query)), self$file, sep = "", useBytes = TRUE)
      invisible(self)
    }
  )
)

#' The JUnit XML of a run, written like the Java implementation of the
#' official formatter, whose output the formatter's test data has
#' @keywords internal
#' @noRd
junit_xml <- function(q) {
  started <- q$test_cases_started_final()
  pickles <- lapply(started, q$pickle_of)
  # By feature file and line, sorted like Java compares strings
  uris <- vapply(pickles, \(pickle) pickle$uri, character(1))
  lines <- vapply(pickles, \(pickle) as.numeric(pickle$location$line %||% -Inf), numeric(1))
  order <- order(uris, lines, method = "radix")

  statuses <- unlist(lapply(started, \(case) q$most_severe_result_of(case)$status))
  run_hooks <- Filter(\(finished) !finished$result$status %in% c("PASSED", "SKIPPED"), q$test_run_hooks_finished)

  suite <- xml_start("testsuite", c(
    name = "Cucumber",
    time = java_seconds(millis_between(q$test_run_started$timestamp, q$test_run_finished$timestamp)),
    tests = length(started),
    skipped = sum(statuses == "SKIPPED"),
    failures = sum(!statuses %in% c("PASSED", "SKIPPED")),
    errors = 0,
    timestamp = if (!is.null(q$test_run_started)) iso_instant(q$test_run_started$timestamp)
  ))
  c(
    '<?xml version="1.0" encoding="UTF-8"?>\n',
    suite, "\n",
    unlist(lapply(run_hooks, \(finished) junit_test_run_hook(q, finished))),
    unlist(lapply(started[order], \(case) junit_test_case(q, case))),
    "</testsuite>\n"
  )
}

junit_test_run_hook <- function(q, finished) {
  started <- q$test_run_hooks_started[[finished$testRunHookStartedId]]
  hook <- q$hooks[[started$hookId]]
  reference <- hook$sourceReference
  name <- if (!is.null(reference$uri)) {
    paste0(reference$uri, if (!is.null(reference$location)) paste0(":", reference$location$line))
  } else {
    "Unknown"
  }
  c(
    xml_start(
      "testcase",
      c(name = name, time = java_seconds(millis_between(started$timestamp, finished$timestamp)))
    ), "\n",
    junit_non_passed(finished$result),
    "</testcase>\n"
  )
}

junit_test_case <- function(q, started) {
  pickle <- q$pickle_of(started)
  lineage <- q$lineage_of(pickle)
  result <- q$most_severe_result_of(started) %||% list(status = "PASSED")
  steps <- Filter(\(step) !is.null(step$test_step$pickleStepId), q$test_steps_of(started))
  output <- vapply(steps, \(step) {
    pickle_step <- q$pickle_steps[[step$test_step$pickleStepId]]
    text <- paste0(q$step_of(pickle_step)$keyword %||% "", pickle_step$text)
    # At least two dots between the step and its status, up to 76 characters
    paste0(text, "..", strrep(".", max(0, 76 - 2 - nchar(text))), tolower(step$finished$testStepResult$status), "\n")
  }, character(1))
  c(
    xml_start("testcase", c(
      classname = lineage$feature$name %||% pickle$uri,
      name = junit_test_name(lineage, pickle),
      time = java_seconds(millis_between(started$timestamp, q$test_cases_finished[[started$id]]$timestamp))
    )), "\n",
    junit_non_passed(result),
    if (length(output) > 0) c("<system-out>", xml_cdata(paste0("\n", paste(output, collapse = ""))), "</system-out>\n"),
    "</testcase>\n"
  )
}

#' A test case's name, like the official naming strategy LONG, without the
#' feature's name and with the example's number, and its pickle's name when
#' the outline's name has placeholders
#' @keywords internal
#' @noRd
junit_test_name <- function(lineage, pickle) {
  scenario <- lineage$scenario$name
  parts <- c(
    lineage$rule$name,
    if (nzchar(scenario %||% "")) scenario else pickle$name,
    lineage$examples$name
  )
  if (!is.null(lineage$example)) {
    number <- paste0("#", lineage$examples_index, ".", lineage$example_index)
    parts <- c(parts, if (!identical(scenario, pickle$name)) paste0(number, ": ", pickle$name) else number)
  }
  paste(parts[nzchar(parts)], collapse = " - ")
}

#' The failure or skipped element of a result that didn't pass
#' @keywords internal
#' @noRd
junit_non_passed <- function(result) {
  status <- result$status
  if (status == "PASSED") {
    return(NULL)
  }
  name <- if (status == "SKIPPED") "skipped" else "failure"
  exception <- result$exception
  attributes <- if (status != "SKIPPED") c(type = exception$type, message = exception$message)
  text <- exception$stackTrace %||% result$message
  if (is.null(text)) {
    return(c(xml_start(name, attributes, empty = TRUE), "\n"))
  }
  c(xml_start(name, attributes), "\n", xml_cdata(text), "\n</", name, ">\n")
}

xml_start <- function(name, attributes = NULL, empty = FALSE) {
  attributes <- attributes[!vapply(attributes, is.null, logical(1))]
  values <- vapply(attributes, \(value) xml_escape(xml_legal(as.character(value))), character(1))
  attributes <- if (length(values) > 0) paste0(" ", names(values), '="', values, '"', collapse = "") else ""
  paste0("<", name, attributes, if (empty) "/>" else ">")
}

xml_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  gsub('"', "&quot;", x, fixed = TRUE)
}

#' CDATA sections of a text, split where the text has `]]>`, which would end one
#' @keywords internal
#' @noRd
xml_cdata <- function(text) {
  parts <- strsplit(xml_legal(text), "(?<=\\]\\])(?=>)", perl = TRUE)[[1]]
  paste0("<![CDATA[", parts, "]]>", collapse = "")
}

#' Characters XML doesn't allow, as character references
#' @keywords internal
#' @noRd
xml_legal <- function(x) {
  codes <- utf8ToInt(x)
  legal <- codes %in% c(0x9, 0xA, 0xD) | (codes >= 0x20 & codes <= 0xD7FF) |
    (codes >= 0xE000 & codes <= 0xFFFD) | codes >= 0x10000
  if (all(legal)) {
    return(x)
  }
  chars <- vapply(codes, intToUtf8, character(1))
  chars[!legal] <- paste0("&#", codes[!legal], ";")
  paste(chars, collapse = "")
}

#' Seconds from milliseconds, written like Java writes a double: `0.0`, `0.057`
#' @keywords internal
#' @noRd
java_seconds <- function(millis) {
  seconds <- millis / 1000
  if (seconds == trunc(seconds)) sprintf("%.1f", seconds) else as.character(seconds)
}

#' A timestamp like Java's ISO_INSTANT: `1970-01-01T00:00:00Z`, with the
#' fraction of a second in groups of three digits
#' @keywords internal
#' @noRd
iso_instant <- function(timestamp) {
  time <- format(as.POSIXct(timestamp$seconds, origin = "1970-01-01", tz = "UTC"), "%Y-%m-%dT%H:%M:%S", tz = "UTC")
  fraction <- if (timestamp$nanos > 0) sub("(000)+$", "", sprintf(".%09d", as.integer(timestamp$nanos)))
  paste0(time, fraction, "Z")
}

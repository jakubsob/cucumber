#' Cucumber HTML Reporter
#'
#' @description
#' Writes the run as the official Cucumber HTML report
#' (<https://github.com/cucumber/html-formatter>). The page is one file that
#' works offline: it shows every feature with its results, and can be searched
#' and filtered by status, text and tags.
#'
#' The report is written when the run ends, even when it fails. To also see
#' the progress of the run, combine it with another reporter in a
#' [CucumberMultiReporter]. To write the report of a run after it ran, store
#' its messages with [CucumberMessagesReporter] and pass their file to
#' `report()`.
#'
#' @seealso Steps and hooks attach screenshots and logs to the report, see
#'   [attachments] and `vignette("reporting", package = "cucumber")`.
#' @examples
#' \dontrun{
#' cucumber::test(reporter = cucumber::CucumberHtmlReporter$new("cucumber-report.html"))
#'
#' # With the progress of the run
#' cucumber::test(reporter = cucumber::CucumberMultiReporter$new(list(
#'   cucumber::CucumberProgressReporter$new(),
#'   cucumber::CucumberHtmlReporter$new("cucumber-report.html")
#' )))
#'
#' # From the messages of a run, after it ran
#' cucumber::test(reporter = cucumber::CucumberMessagesReporter$new("cucumber.ndjson"))
#' cucumber::CucumberHtmlReporter$new("cucumber-report.html")$report("cucumber.ndjson")
#' }
#'
#' @eval features_rd(features = "r-html_reporter.feature")
#'
#' @export
CucumberHtmlReporter <- R6::R6Class(
  "CucumberHtmlReporter",
  inherit = CucumberReporter,
  public = list(
    #' @field file Path of the HTML file the report is written to
    file = NULL,

    #' @description
    #' Create an HTML reporter
    #' @param file Path of the HTML file to write, replaced by each run. A
    #'   relative path is relative to the working directory when the reporter
    #'   is created.
    initialize = function(file = "cucumber-report.html") {
      rlang::check_installed("jsonlite", "to write Cucumber Messages.")
      self$file <- as.character(fs::path_abs(file))
    },

    #' @description
    #' Start collecting the messages of a run
    start_run = function() {
      private$lines <- character()
      invisible(self)
    },

    #' @description
    #' Collect a message of the run
    #' @param envelope A list with one element, named by the message's type
    add_message = function(envelope) {
      private$lines <- c(private$lines, envelope_json(envelope))
      invisible(self)
    },

    #' @description
    #' Write the report
    #' @param error The error that stopped the run, or `NULL`
    end_run = function(error = NULL) {
      writeLines(enc2utf8(html_report(private$lines)), self$file, useBytes = TRUE)
      invisible(self)
    }
  ),
  private = list(
    lines = character()
  )
)

#' The page of the official HTML report with the messages of a run, each a
#' line of JSON
#' @keywords internal
#' @noRd
html_report <- function(lines) {
  formatter <- \(file) {
    paste(readLines(system.file("html-formatter", file, package = "cucumber"), encoding = "UTF-8", warn = FALSE), collapse = "\n")
  }
  values <- list(
    title = "Cucumber",
    icon = formatter("icon.url"),
    css = formatter("main.css"),
    custom_css = "",
    # Like the official formatter: a `<` in a script could end it, so it's
    # escaped, which JavaScript reads back as `<`
    messages = gsub("<", "\\x3C", paste(lines, collapse = ","), fixed = TRUE),
    script = formatter("main.js"),
    custom_script = ""
  )

  page <- formatter("index.mustache")
  placeholders <- gregexpr("\\{\\{\\w+\\}\\}", page)
  regmatches(page, placeholders) <- list(unlist(values[gsub("[{}]", "", regmatches(page, placeholders)[[1]])]))
  page
}

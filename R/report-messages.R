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
    #'   working directory when the reporter is created. Its
    #'   directory is created when the reporter is, if it doesn't exist.
    initialize = function(file = "cucumber.ndjson") {
      rlang::check_installed("jsonlite", "to write Cucumber Messages.")
      self$file <- if (is.character(file)) report_path(file) else file
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

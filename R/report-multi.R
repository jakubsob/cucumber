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
      for (i in seq_along(reporters)) check_reporter(reporters[[i]], call = NULL, arg = paste0("reporters[[", i, "]]"))
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

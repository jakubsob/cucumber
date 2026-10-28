#' Cucumber Rerun Reporter
#'
#' @description
#' Writes where the scenarios that didn't pass are, like Cucumber's `rerun`
#' formatter: a line for each feature file, with the line of each of its
#' scenarios that didn't pass, like `basket.feature:3:12`. Pass them to the
#' `features` argument of [test()] to run only those scenarios again. To also
#' see the progress of the run, combine it with another reporter in a
#' [CucumberMultiReporter].
#'
#' @examples
#' \dontrun{
#' cucumber::test(reporter = cucumber::CucumberMultiReporter$new(list(
#'   cucumber::CucumberProgressReporter$new(),
#'   cucumber::CucumberRerunReporter$new("rerun.txt")
#' )))
#'
#' # Run the scenarios that didn't pass again
#' cucumber::test(features = readLines("rerun.txt"))
#' }
#'
#' @eval features_rd(features = "r-rerun_reporter.feature")
#'
#' @export
CucumberRerunReporter <- R6::R6Class(
  "CucumberRerunReporter",
  inherit = CucumberQueryReporter,
  public = list(
    #' @field file Path of the file the scenarios are written to
    file = NULL,

    #' @description
    #' Create a rerun reporter
    #' @param file Path of the file to write, replaced by each run. A relative
    #'   path is relative to the working directory when the reporter is created. Its
    #'   directory is created when the reporter is, if it doesn't exist.
    initialize = function(file = "rerun.txt") {
      self$file <- report_path(file)
    },

    #' @description
    #' Write the scenarios that didn't pass
    #' @param error The error that stopped the run, or `NULL`
    end_run = function(error = NULL) {
      writeLines(enc2utf8(rerun_lines(private$query)), self$file, useBytes = TRUE)
      invisible(self)
    }
  )
)

#' The scenarios whose last attempt didn't pass, by feature
#' file in the order they ran
#' @keywords internal
#' @noRd
rerun_lines <- function(q) {
  started <- Filter(
    \(case) (q$most_severe_result_of(case)$status %||% "PASSED") != "PASSED",
    q$test_cases_started_final()
  )
  pickles <- lapply(started, q$pickle_of)
  uris <- vapply(pickles, \(pickle) pickle$uri, character(1))
  lines <- vapply(pickles, \(pickle) as.integer(pickle$location$line), integer(1))
  by_uri <- split(lines, factor(uris, unique(uris)))
  as.character(unlist(Map(\(uri, lines) paste(c(uri, lines), collapse = ":"), names(by_uri), by_uri)))
}

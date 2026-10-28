#' Cucumber Snippets Reporter
#'
#' @description
#' Prints only the snippets of the step definitions that undefined steps need,
#' like Cucumber's `snippets` formatter, to paste them into a setup file. A step
#' undefined in several scenarios gets one snippet.
#'
#' ```
#' when("I add {int} cucumbers", function(int, context) {
#' # when("I add {float} cucumbers", function(float, context) {
#'   pending()
#' })
#' ```
#'
#' @examples
#' \dontrun{
#' cucumber::test(reporter = cucumber::CucumberSnippetsReporter$new())
#' }
#'
#' @eval features_rd(features = "r-snippets_reporter.feature")
#'
#' @export
CucumberSnippetsReporter <- R6::R6Class(
  "CucumberSnippetsReporter",
  inherit = CucumberReporter,
  public = list(
    #' @description
    #' Create a snippets reporter
    #' @param file Path of a file to print to instead of the console, replaced
    #'   by each run, or `NULL`. A relative path is relative to the working
    #'   directory when the reporter is created. Its directory is created when
    #'   the reporter is, if it doesn't exist.
    initialize = function(file = NULL) {
      if (!is.null(file)) self$output <- report_path(file)
    },

    #' @description
    #' Start collecting the snippets of a run
    start_run = function() {
      private$snippets <- character()
      invisible(self)
    },

    #' @description
    #' Collect the snippets of an undefined step
    #' @param envelope A list with one element, named by the message's type
    add_message = function(envelope) {
      suggestion <- envelope$suggestion
      if (!is.null(suggestion)) {
        # The first line of each step definition, the others commented out
        definitions <- vapply(
          suggestion$snippets, \(snippet) strsplit(snippet$code, "\n", fixed = TRUE)[[1]][[1]], character(1)
        )
        private$snippets <- c(private$snippets, format_step_snippet(definitions))
      }
      invisible(self)
    },

    #' @description
    #' Print the snippets
    #' @param error The error that stopped the run, or `NULL`
    end_run = function(error = NULL) {
      snippets <- unique(private$snippets)
      if (length(snippets) > 0) {
        cat(snippets, sep = "\n\n")
        cat("\n")
      }
      invisible(self)
    }
  ),
  private = list(
    snippets = character()
  )
)

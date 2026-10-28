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
    #' @param file Path of a file to print to instead of the console, replaced
    #'   by each run, or `NULL`
    initialize = function(file = NULL) {
      super$initialize(file)
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

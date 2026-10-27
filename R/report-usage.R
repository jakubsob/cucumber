#' Cucumber Usage Reporter
#'
#' @description
#' Prints how each step definition was used when the run ends, like Cucumber's
#' `usage` formatter: its expression, the mean duration of its steps and where
#' it's defined, then the steps it matched, the slowest first. A step definition
#' no step matched is `UNUSED`. Use it to find slow steps and step definitions
#' to remove. To also see the progress of the run, combine it with another
#' reporter in a [CucumberMultiReporter].
#'
#' ```
#' Step definition / Step         Duration  Location
#' I add {int} apples             1.52ms    setup-steps.R:3
#'   I add 2 apples               2.01ms    basket.feature:4
#'   I add 1 apples               1.03ms    basket.feature:9
#' I remove {int} apples          UNUSED    setup-steps.R:6
#' ```
#'
#' @examples
#' \dontrun{
#' cucumber::test(reporter = cucumber::CucumberUsageReporter$new())
#' }
#'
#' @eval features_rd(features = "r-usage_reporter.feature")
#'
#' @export
CucumberUsageReporter <- R6::R6Class(
  "CucumberUsageReporter",
  inherit = CucumberReporter,
  public = list(
    #' @description
    #' Create a usage reporter
    #' @param file Path of a file to print to instead of the console, replaced
    #'   by each run, or `NULL`. A relative path is relative to the working
    #'   directory when the reporter is created. Its directory is created when
    #'   the reporter is, if it doesn't exist.
    initialize = function(file = NULL) {
      if (!is.null(file)) self$output <- report_path(file)
    },

    #' @description
    #' Start following the messages of a run
    start_run = function() {
      private$query <- new_query()
      invisible(self)
    },

    #' @description
    #' Follow a message of the run
    #' @param envelope A list with one element, named by the message's type
    add_message = function(envelope) {
      private$query$update(envelope)
      invisible(self)
    },

    #' @description
    #' Print the usage of the step definitions
    #' @param error The error that stopped the run, or `NULL`
    end_run = function(error = NULL) {
      rows <- usage_rows(private$query)
      if (nrow(rows) > 0) {
        cat(format_usage(rows), sep = "\n")
      } else {
        cat("No step definitions\n")
      }
      invisible(self)
    }
  ),
  private = list(
    query = NULL
  )
)

# Steps listed under a step definition, the slowest ones
USAGE_MATCHES <- 5L

#' The rows of the usage report, as text: each step definition, the slowest
#' first and the unused ones last, followed by the steps it matched, the
#' slowest first
#' @return A data frame of `text`, `duration` and `location`
#' @keywords internal
#' @noRd
usage_rows <- function(q) {
  matches <- list()
  for (started in q$test_cases_started_final()) {
    pickle <- q$pickle_of(started)
    for (step in q$test_steps_of(started)) {
      ids <- unlist(step$test_step$stepDefinitionIds)
      # An ambiguous step isn't a use of any of its step definitions
      if (length(ids) != 1) next
      pickle_step <- q$pickle_steps[[step$test_step$pickleStepId]]
      result <- step$finished$testStepResult
      matches[[ids]] <- rbind(matches[[ids]], data.frame(
        text = paste0("  ", pickle_step$text),
        # A skipped step didn't run
        seconds = if (result$status == "SKIPPED") NA_real_ else result$duration$seconds + result$duration$nanos / 1e9,
        location = paste0(pickle$uri, ":", q$step_of(pickle_step)$location$line)
      ))
    }
  }

  definitions <- lapply(unname(q$step_definitions), \(definition) {
    steps <- matches[[definition$id]]
    reference <- definition$sourceReference
    pattern <- definition$pattern
    row <- data.frame(
      text = if (pattern$type == "REGULAR_EXPRESSION") paste0("/", pattern$source, "/") else pattern$source,
      seconds = if (is.null(steps)) NA_real_ else mean(steps$seconds, na.rm = TRUE),
      location = if (!is.null(reference$uri)) paste0(fs::path_rel(reference$uri), ":", reference$location$line) else ""
    )
    if (is.null(steps)) {
      row$duration <- "UNUSED"
      return(row)
    }
    steps <- steps[order(steps$seconds, decreasing = TRUE, na.last = TRUE), ]
    more <- nrow(steps) - USAGE_MATCHES
    steps <- utils::head(steps, USAGE_MATCHES)
    rows <- rbind(row, steps)
    rows$duration <- ifelse(is.na(rows$seconds), "-", sprintf("%.2fms", rows$seconds * 1000))
    if (more > 0) {
      rows <- rbind(rows, data.frame(text = paste0("  ... ", more, " more"), seconds = NA_real_, location = "", duration = ""))
    }
    rows
  })
  # The slowest first, the unused ones last
  unused <- vapply(definitions, \(rows) rows$duration[[1]] == "UNUSED", logical(1))
  seconds <- vapply(definitions, \(rows) rows$seconds[[1]], numeric(1))
  rows <- do.call(rbind, c(
    list(data.frame(text = character(), seconds = numeric(), location = character(), duration = character())),
    definitions[order(unused, -seconds, na.last = TRUE)]
  ))
  rows[c("text", "duration", "location")]
}

#' The lines of the usage report, in aligned columns
#' @keywords internal
#' @noRd
format_usage <- function(rows) {
  # Not formatC(), which counts a backslash as two characters
  column <- \(header, values) {
    x <- c(header, values)
    paste0(x, strrep(" ", max(nchar(x)) - nchar(x)))
  }
  lines <- paste(
    column("Step definition / Step", rows$text),
    column("Duration", rows$duration),
    c("Location", rows$location),
    sep = "  "
  )
  trimws(lines, "right")
}

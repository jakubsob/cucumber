#' Read the Cucumber Messages of a run
#'
#' Reads the messages a [CucumberMessagesReporter] wrote, to write a report of
#' your own.
#'
#' @param x Path of a Cucumber Messages file, its lines, or the
#'   [CucumberMessagesReporter] that wrote it.
#' @return A `cucumber_messages` object, a list with:
#'   \describe{
#'     \item{`features`}{A tibble with a row per feature: its `uri`, `name`,
#'       `description` and `tags`.}
#'     \item{`scenarios`}{A tibble with a row per scenario that ran, each
#'       example of an outline being one: its `id`, the `uri`, `feature` and
#'       `rule` it's in, its `name`, `line`, `tags`, `status` (the worst of its
#'       steps' and hooks'), `duration` in seconds and how many `attempts` it
#'       took, more than one if it was retried. A retried scenario's row and
#'       steps are of its last attempt.}
#'     \item{`steps`}{A tibble with a row per step and hook of each scenario: the
#'       `scenario_id` and `scenario` it ran in, its `keyword` (`Before` or
#'       `After` for a hook), `text` (a hook's name), `status`, `duration` in
#'       seconds and the `error` of a step that didn't pass.}
#'     \item{`envelopes`}{The messages, as lists.}
#'     \item{`lines`}{The messages, as the lines of the ndjson file.}
#'   }
#'
#' @examples
#' \dontrun{
#' # A Markdown summary of the steps that failed, e.g. for a CI job's summary
#' cucumber::test(reporter = cucumber::CucumberMessagesReporter$new("cucumber.ndjson"))
#' run <- cucumber::read_messages("cucumber.ndjson")
#' failed <- run$steps[run$steps$status == "failed", ]
#' writeLines(paste0("- ", failed$scenario, ": ", failed$keyword, " ", failed$text), "summary.md")
#' }
#' @eval features_rd(features = "r-custom_report.feature")
#' @export
read_messages <- function(x) {
  rlang::check_installed("jsonlite", "to read Cucumber Messages.")
  if (inherits(x, "CucumberMessagesReporter")) {
    x <- x$file
  }
  lines <- if (length(x) == 1 && !startsWith(trimws(x), "{")) readLines(x, warn = FALSE, encoding = "UTF-8") else x
  lines <- lines[nzchar(lines)]
  envelopes <- lapply(lines, jsonlite::fromJSON, simplifyVector = FALSE)
  q <- new_query()
  for (envelope in envelopes) q$update(envelope)
  documents <- Filter(Negate(is.null), lapply(envelopes, `[[`, "gherkinDocument"))
  seconds <- \(duration) duration$seconds + duration$nanos / 1e9
  # Only the last attempt of a retried scenario
  started <- q$test_cases_started_final()

  scenarios <- lapply(started, \(case) {
    pickle <- q$pickle_of(case)
    lineage <- q$lineage_of(pickle)
    results <- lapply(q$test_steps_of(case), \(step) step$finished$testStepResult)
    tibble::tibble(
      id = case$id,
      uri = pickle$uri,
      feature = lineage$feature$name,
      rule = lineage$rule$name %||% NA_character_,
      name = pickle$name,
      line = (lineage$example %||% lineage$scenario)$location$line,
      tags = list(vapply(pickle$tags, \(tag) tag$name, character(1))),
      status = tolower(q$most_severe_result_of(case)$status %||% "PASSED"),
      duration = sum(vapply(results, \(result) seconds(result$duration), numeric(1))),
      attempts = (case$attempt %||% 0L) + 1L
    )
  })
  steps <- lapply(started, \(case) {
    lapply(q$test_steps_of(case), \(step) {
      result <- step$finished$testStepResult
      status <- tolower(result$status)
      hook <- q$hooks[[step$test_step$hookId %||% ""]]
      pickle_step <- q$pickle_steps[[step$test_step$pickleStepId %||% ""]]
      tibble::tibble(
        scenario_id = case$id,
        scenario = q$pickle_of(case)$name,
        keyword = if (is.null(pickle_step)) {
          if (startsWith(hook$type %||% "", "AFTER")) "After" else "Before"
        } else {
          trimws(q$step_of(pickle_step)$keyword)
        },
        text = if (is.null(pickle_step)) hook$name %||% "" else pickle_step$text,
        status = status,
        duration = seconds(result$duration),
        error = if (status != "passed" && !is.null(result$message)) cli::ansi_strip(result$message) else NA_character_
      )
    })
  })
  features <- lapply(Filter(\(document) !is.null(document$feature), documents), \(document) {
    feature <- document$feature
    tibble::tibble(
      uri = document$uri,
      name = feature$name,
      description = trimws(dedent(feature$description)),
      tags = list(vapply(feature$tags, \(tag) tag$name, character(1)))
    )
  })

  structure(
    list(
      features = rows(
        features,
        tibble::tibble(uri = character(), name = character(), description = character(), tags = list())
      ),
      scenarios = rows(scenarios, tibble::tibble(
        id = character(), uri = character(), feature = character(), rule = character(), name = character(),
        line = integer(), tags = list(), status = character(), duration = numeric(), attempts = integer()
      )),
      steps = rows(unlist(steps, recursive = FALSE), tibble::tibble(
        scenario_id = character(), scenario = character(), keyword = character(), text = character(),
        status = character(), duration = numeric(), error = character()
      )),
      envelopes = envelopes,
      lines = lines
    ),
    class = "cucumber_messages"
  )
}

#' Rows bound into one tibble, or the empty one when there are none
#' @keywords internal
#' @noRd
rows <- function(rows, empty) {
  if (length(rows)) purrr::list_rbind(rows) else empty
}

#' Text without the indentation its lines share
#' @keywords internal
#' @noRd
dedent <- function(text) {
  lines <- strsplit(text, "\n", fixed = TRUE)[[1]]
  indents <- nchar(sub("\\S.*", "", lines[nzchar(trimws(lines))]))
  if (length(indents) == 0) {
    return(text)
  }
  paste(substring(lines, min(indents) + 1), collapse = "\n")
}

#' @export
print.cucumber_messages <- function(x, ...) {
  features <- paste0(nrow(x$features), " feature", if (nrow(x$features) != 1) "s")
  scenarios <- cli::ansi_strip(format_status_counts(x$scenarios$status, "scenario"))
  cat("<cucumber_messages>", paste0(features, ", ", scenarios), "\n")
  invisible(x)
}

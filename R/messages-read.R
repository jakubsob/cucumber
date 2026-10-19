#' Read the Cucumber Messages of a run
#'
#' Reads the messages a [CucumberMessagesReporter] wrote, as tibbles of a run's
#' features, scenarios and steps, to write a report of your own or query the
#' results.
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
#'       steps' and hooks') and `duration` in seconds.}
#'     \item{`steps`}{A tibble with a row per step and hook that ran: the
#'       `scenario_id` and `scenario` it ran in, its `keyword` (`Before` or
#'       `After` for a hook), `text` (a hook's name), `status`, `duration` in
#'       seconds and the `error` of a step that didn't pass.}
#'     \item{`envelopes`}{The messages, as lists.}
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
#' @export
read_messages <- function(x) {
  if (inherits(x, "cucumber_messages")) {
    return(x)
  }
  rlang::check_installed("jsonlite", "to read Cucumber Messages.")
  if (inherits(x, "CucumberMessagesReporter")) {
    x <- x$file
  }
  lines <- if (length(x) == 1 && !startsWith(trimws(x), "{")) readLines(x, warn = FALSE, encoding = "UTF-8") else x
  lines <- lines[nzchar(lines)]
  envelopes <- lapply(lines, jsonlite::fromJSON, simplifyVector = FALSE)
  of <- \(type) Filter(Negate(is.null), lapply(envelopes, `[[`, type))
  by_id <- \(messages) set_names(messages, vapply(messages, \(message) message$id, character(1)))
  documents <- of("gherkinDocument")
  pickles <- by_id(of("pickle"))
  test_cases <- by_id(of("testCase"))
  started <- by_id(of("testCaseStarted"))
  hooks <- by_id(of("hook"))

  # From the documents: the keyword of each step, the line of each scenario
  # and example row, and the rule of each scenario
  keywords <- list()
  locations <- list()
  rules <- list()
  walk <- function(children, rule) {
    for (child in children) {
      node <- child$background %||% child$scenario
      for (step in node$steps) keywords[[step$id]] <<- trimws(step$keyword)
      if (!is.null(child$scenario)) {
        locations[[node$id]] <<- node$location$line
        rules[[node$id]] <<- rule
        for (examples in node$examples) {
          for (row in examples$tableBody) locations[[row$id]] <<- row$location$line
        }
      }
      if (!is.null(child$rule)) walk(child$rule$children, child$rule$name)
    }
  }
  for (document in documents) walk(document$feature$children, NA_character_)

  # The results of each test case, in the order its steps and hooks ran
  results <- lapply(started, \(case) list())
  for (finished in of("testStepFinished")) {
    test_case <- test_cases[[started[[finished$testCaseStartedId]]$testCaseId]]
    test_step <- Find(\(step) step$id == finished$testStepId, test_case$testSteps)
    result <- finished$testStepResult
    entry <- list(
      status = tolower(result$status),
      duration = result$duration$seconds + result$duration$nanos / 1e9,
      message = if (!is.null(result$message)) cli::ansi_strip(result$message)
    )
    if (is.null(test_step$pickleStepId)) {
      entry$hook <- hooks[[test_step$hookId]]
    } else {
      entry$step <- Find(\(step) step$id == test_step$pickleStepId, pickles[[test_case$pickleId]]$steps)
    }
    results[[finished$testCaseStartedId]] <- c(results[[finished$testCaseStartedId]], list(entry))
  }
  worst <- \(statuses) if (length(statuses)) STEP_STATUSES[STEP_STATUSES %in% statuses][[1]] else "passed"

  scenarios <- lapply(names(started), \(id) {
    pickle <- pickles[[test_cases[[started[[id]]$testCaseId]]$pickleId]]
    ast_ids <- unlist(pickle$astNodeIds)
    key <- ast_ids[[length(ast_ids)]]
    case <- results[[id]]
    case_status <- worst(vapply(case, \(entry) entry$status, character(1)))
    document <- Find(\(document) document$uri == pickle$uri, documents)
    tibble::tibble(
      id = id,
      uri = pickle$uri,
      feature = document$feature$name,
      rule = rules[[ast_ids[[1]]]],
      name = pickle$name,
      line = locations[[key]],
      tags = list(vapply(pickle$tags, \(tag) tag$name, character(1))),
      status = case_status,
      duration = sum(vapply(case, \(entry) entry$duration, numeric(1)))
    )
  })
  steps <- lapply(names(started), \(id) {
    lapply(results[[id]], \(entry) {
      hook <- !is.null(entry$hook)
      tibble::tibble(
        scenario_id = id,
        scenario = pickles[[test_cases[[started[[id]]$testCaseId]]$pickleId]]$name,
        keyword = if (hook) (if (startsWith(entry$hook$type %||% "", "AFTER")) "After" else "Before") else keywords[[entry$step$astNodeIds[[1]]]],
        text = if (hook) entry$hook$name %||% "" else entry$step$text,
        status = entry$status,
        duration = entry$duration,
        error = if (entry$status != "passed") entry$message %||% NA_character_ else NA_character_
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
      features = rows(features, tibble::tibble(uri = character(), name = character(), description = character(), tags = list())),
      scenarios = rows(scenarios, tibble::tibble(
        id = character(), uri = character(), feature = character(), rule = character(), name = character(),
        line = integer(), tags = list(), status = character(), duration = numeric()
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

#' Count of scenarios by status, like the summary of a run:
#' "3 scenarios (1 failed, 2 passed)"
#' @keywords internal
#' @noRd
scenario_summary <- function(scenarios) {
  counts <- table(factor(scenarios$status, STEP_STATUSES))
  counts <- counts[counts > 0]
  paste0(nrow(scenarios), " scenarios", if (length(counts)) paste0(" (", paste(counts, names(counts), collapse = ", "), ")"))
}

#' @export
print.cucumber_messages <- function(x, ...) {
  cat("<cucumber_messages>", paste0(nrow(x$features), " features, ", scenario_summary(x$scenarios)), "\n")
  invisible(x)
}

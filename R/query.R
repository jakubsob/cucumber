#' A query of a run's messages, like the official cucumber/query
#'
#' Messages are added one at a time with `update()`, as a reporter gets them,
#' and the query finds what they refer to: the pickle of a test case, the
#' Gherkin step of a pickle step, the feature, rule and examples a pickle
#' comes from.
#'
#' @return An environment with the messages by id, and functions to find
#'   them.
#' @keywords internal
#' @noRd
new_query <- function() {
  q <- new.env(parent = emptyenv())
  q$pickles <- list()
  q$pickle_steps <- list()
  q$steps <- list()
  q$lineages <- list()
  q$test_cases <- list()
  q$test_steps <- list()
  q$test_cases_started <- list()
  q$test_cases_finished <- list()
  q$test_steps_finished <- list()
  q$hooks <- list()
  q$step_definitions <- list()
  q$test_run_hooks_started <- list()
  q$test_run_hooks_finished <- list()
  q$test_run_started <- NULL
  q$test_run_finished <- NULL

  q$update <- function(envelope) {
    type <- names(envelope)
    message <- envelope[[1]]
    switch(
      type,
      gherkinDocument = index_document(q, message),
      pickle = {
        q$pickles[[message$id]] <- message
        for (step in message$steps) q$pickle_steps[[step$id]] <- step
      },
      hook = q$hooks[[message$id]] <- message,
      stepDefinition = q$step_definitions[[message$id]] <- message,
      testRunStarted = q$test_run_started <- message,
      testRunFinished = q$test_run_finished <- message,
      testRunHookStarted = q$test_run_hooks_started[[message$id]] <- message,
      testRunHookFinished = q$test_run_hooks_finished <- c(q$test_run_hooks_finished, list(message)),
      testCase = {
        q$test_cases[[message$id]] <- message
        for (step in message$testSteps) q$test_steps[[step$id]] <- step
      },
      testCaseStarted = {
        q$test_cases_started[[message$id]] <- message
        q$test_steps_finished[[message$id]] <- list()
      },
      testStepFinished = {
        id <- message$testCaseStartedId
        q$test_steps_finished[[id]] <- c(q$test_steps_finished[[id]], list(message))
      },
      testCaseFinished = q$test_cases_finished[[message$testCaseStartedId]] <- message
    )
    invisible(q)
  }

  # Test cases started that won't be retried, in the order they started
  q$test_cases_started_final <- function() {
    Filter(\(started) !isTRUE(q$test_cases_finished[[started$id]]$willBeRetried), unname(q$test_cases_started))
  }
  q$pickle_of <- function(test_case_started) {
    q$pickles[[q$test_cases[[test_case_started$testCaseId]]$pickleId]]
  }
  # The pickle's feature, rule, scenario, examples and example row
  q$lineage_of <- function(pickle) {
    ids <- unlist(pickle$astNodeIds)
    q$lineages[[ids[[length(ids)]]]]
  }
  # The Gherkin step of a pickle step
  q$step_of <- function(pickle_step) {
    q$steps[[pickle_step$astNodeIds[[1]]]]
  }
  # Each finished test step of a test case, with its test step
  q$test_steps_of <- function(test_case_started) {
    lapply(q$test_steps_finished[[test_case_started$id]], \(finished) {
      list(finished = finished, test_step = q$test_steps[[finished$testStepId]])
    })
  }
  # The result of the test case's test step that is the worst, the last one
  # of them when several are, or NULL when it has no test steps
  q$most_severe_result_of <- function(test_case_started) {
    results <- lapply(q$test_steps_finished[[test_case_started$id]], \(finished) finished$testStepResult)
    if (length(results) == 0) {
      return(NULL)
    }
    severity <- vapply(results, \(result) status_severity(result$status), integer(1))
    results[[max(which(severity == max(severity)))]]
  }
  q
}

#' The steps of a Gherkin document by id, and the lineage of each of its
#' scenarios and example rows
#' @keywords internal
#' @noRd
index_document <- function(q, document) {
  feature <- document$feature
  walk <- function(children, rule = NULL) {
    for (child in children) {
      node <- child$background %||% child$scenario
      for (step in node$steps) q$steps[[step$id]] <- step
      if (!is.null(child$scenario)) {
        lineage <- list(document = document, feature = feature, rule = rule, scenario = node)
        q$lineages[[node$id]] <- lineage
        for (i in seq_along(node$examples)) {
          examples <- node$examples[[i]]
          for (j in seq_along(examples$tableBody)) {
            row <- examples$tableBody[[j]]
            q$lineages[[row$id]] <- c(
              lineage,
              list(examples = examples, examples_index = i, example = row, example_index = j)
            )
          }
        }
      }
      if (!is.null(child$rule)) walk(child$rule$children, child$rule)
    }
  }
  walk(feature$children)
}

#' The severity of a step result's status, like the official statusOrdinal
#' @keywords internal
#' @noRd
status_severity <- function(status) {
  match(status, c("UNKNOWN", "PASSED", "SKIPPED", "PENDING", "UNDEFINED", "AMBIGUOUS", "FAILED"))
}

#' Milliseconds between two timestamps, truncated like Java's Duration
#' @keywords internal
#' @noRd
millis_between <- function(start, end) {
  if (is.null(start) || is.null(end)) {
    return(0)
  }
  floor(((end$seconds - start$seconds) * 1e9 + (end$nanos - start$nanos)) / 1e6)
}

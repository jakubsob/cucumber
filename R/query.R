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
  # What the reporters print of a test case, from its messages so far: its
  # pickle and lineage, attempt, status, the steps run with their results, and
  # the hooks that failed, are pending or skipped it, with the number of steps
  # run before each
  q$scenario_of <- function(test_case_started) {
    pickle <- q$pickle_of(test_case_started)
    steps <- list()
    hooks <- list()
    for (finished in q$test_steps_finished[[test_case_started$id]]) {
      result <- finished$testStepResult
      pickle_step_id <- q$test_steps[[finished$testStepId]]$pickleStepId
      if (!is.null(pickle_step_id)) {
        steps <- c(steps, list(reported_step(q, q$pickle_steps[[pickle_step_id]], result)))
      } else if (!is.null(result$message)) {
        hooks <- c(
          hooks,
          list(list(status = tolower(result$status), error = result$message, after_steps = length(steps)))
        )
      }
    }
    list(
      pickle = pickle,
      lineage = q$lineage_of(pickle),
      attempt = test_case_started$attempt,
      status = tolower(q$most_severe_result_of(test_case_started)$status %||% "PASSED"),
      steps = steps,
      hooks = hooks
    )
  }
  q
}

#' A pickle step and its result, as the reporters print it: its keyword as
#' written, text, status, error message, and the lines of its Doc String or
#' the rows of its Data Table
#'
#' @keywords internal
#' @noRd
reported_step <- function(q, pickle_step, result) {
  argument <- pickle_step$argument
  step <- q$step_of(pickle_step)
  content <- argument$docString$content
  list(
    # Its space too, as some keywords have none, like `假如` in Chinese
    keyword = step$keyword,
    text = pickle_step$text,
    status = tolower(result$status),
    error = result$message,
    docstring = if (!is.null(argument$docString)) {
      list(
        delimiter = step$docString$delimiter %||% '"""',
        media_type = argument$docString$mediaType,
        # With its empty lines at the end
        lines = if (nzchar(content)) stringi::stri_split_fixed(content, "\n")[[1]] else character()
      )
    },
    data_table = if (!is.null(argument$dataTable)) {
      lapply(argument$dataTable$rows, \(row) {
        vapply(row$cells, \(cell) cell$value, character(1))
      })
    },
    data_table_first = !is.null(step$dataTable) && !is.null(step$docString) &&
      step$dataTable$location$line < step$docString$location$line
  )
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

#' Cucumber Query Reporter
#'
#' @description
#' The parent of the reporters that report a run when it ends, from what
#' `new_query()` indexed of its messages, in `private$query`.
#'
#' @keywords internal
CucumberQueryReporter <- R6::R6Class(
  "CucumberQueryReporter",
  inherit = CucumberReporter,
  public = list(
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
    }
  ),
  private = list(
    query = NULL
  )
)

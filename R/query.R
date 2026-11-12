#' A query of a run's messages, like the official cucumber/query
#'
#' Messages are added one at a time with `update()`, as a reporter gets them,
#' and the query finds what they refer to: the pickle of a test case, the
#' Gherkin step of a pickle step, the feature, rule and examples a pickle
#' comes from.
#'
#' @return An environment of functions that find what the messages say. The
#'   messages themselves are private.
#' @keywords internal
#' @noRd
new_query <- function() {
  # The messages by id, private to the query: callers use its functions
  s <- new.env(parent = emptyenv())
  q <- new.env(parent = emptyenv())
  s$pickles <- list()
  s$pickle_steps <- list()
  s$steps <- list()
  s$lineages <- list()
  s$test_cases <- list()
  s$test_steps <- list()
  s$test_cases_started <- list()
  s$test_cases_finished <- list()
  s$test_steps_finished <- list()
  s$hooks <- list()
  s$step_definitions <- list()
  s$test_run_hooks_started <- list()
  s$test_run_hooks_finished <- list()
  s$test_run_started <- NULL
  s$test_run_finished <- NULL

  q$update <- function(envelope) {
    type <- names(envelope)
    message <- envelope[[1]]
    switch(
      type,
      gherkinDocument = index_document(s, message),
      pickle = {
        s$pickles[[message$id]] <- message
        for (step in message$steps) s$pickle_steps[[step$id]] <- step
      },
      hook = s$hooks[[message$id]] <- message,
      stepDefinition = s$step_definitions[[message$id]] <- message,
      testRunStarted = s$test_run_started <- message,
      testRunFinished = s$test_run_finished <- message,
      testRunHookStarted = s$test_run_hooks_started[[message$id]] <- message,
      testRunHookFinished = s$test_run_hooks_finished <- c(s$test_run_hooks_finished, list(message)),
      testCase = {
        s$test_cases[[message$id]] <- message
        for (step in message$testSteps) s$test_steps[[step$id]] <- step
      },
      testCaseStarted = {
        s$test_cases_started[[message$id]] <- message
        s$test_steps_finished[[message$id]] <- list()
      },
      testStepFinished = {
        id <- message$testCaseStartedId
        s$test_steps_finished[[id]] <- c(s$test_steps_finished[[id]], list(message))
      },
      testCaseFinished = s$test_cases_finished[[message$testCaseStartedId]] <- message
    )
    invisible(q)
  }

  # Test cases started that won't be retried, in the order they started
  q$test_cases_started_final <- function() {
    Filter(\(started) !isTRUE(s$test_cases_finished[[started$id]]$willBeRetried), unname(s$test_cases_started))
  }
  q$pickle_of <- function(test_case_started) {
    s$pickles[[s$test_cases[[test_case_started$testCaseId]]$pickleId]]
  }
  # The pickle's feature, rule, scenario, examples and example row
  q$lineage_of <- function(pickle) {
    ids <- unlist(pickle$astNodeIds)
    s$lineages[[ids[[length(ids)]]]]
  }
  # The Gherkin step of a pickle step
  q$step_of <- function(pickle_step) {
    s$steps[[pickle_step$astNodeIds[[1]]]]
  }
  # Each finished test step of a test case, with its test step and the pickle
  # step or hook it runs, the other one being NULL
  q$test_steps_of <- function(test_case_started) {
    lapply(s$test_steps_finished[[test_case_started$id]], \(finished) {
      test_step <- s$test_steps[[finished$testStepId]]
      list(
        finished = finished,
        test_step = test_step,
        pickle_step = s$pickle_steps[[test_step$pickleStepId %||% ""]],
        hook = s$hooks[[test_step$hookId %||% ""]]
      )
    })
  }
  # Each step definition of the run, in the order they were defined
  q$step_definitions <- function() unname(s$step_definitions)
  # The test case started that a message of its steps refers to
  q$started_of <- function(message) {
    s$test_cases_started[[message$testCaseStartedId]]
  }
  # Whether a message of a test step is about a step of the pickle, not a hook
  q$is_pickle_step <- function(message) {
    !is.null(s$test_steps[[message$testStepId]]$pickleStepId)
  }
  # The status, in capitals, of the worst result of a test case: PASSED when
  # it has no test steps
  q$status_of <- function(test_case_started) {
    q$most_severe_result_of(test_case_started)$status %||% "PASSED"
  }
  # Milliseconds a test case took, from when it started to when it finished
  q$millis_of <- function(test_case_started) {
    millis_between(test_case_started$timestamp, s$test_cases_finished[[test_case_started$id]]$timestamp)
  }
  # Whether the run finished, and when it started (NULL before it did)
  q$run_finished <- function() !is.null(s$test_run_finished)
  q$run_started_at <- function() s$test_run_started$timestamp
  # Milliseconds the run took, from its start to its end
  q$run_millis <- function() {
    millis_between(s$test_run_started$timestamp, s$test_run_finished$timestamp)
  }
  # Milliseconds all test steps of the run took, every attempt included
  q$steps_millis <- function() {
    durations <- lapply(unlist(s$test_steps_finished, recursive = FALSE), \(finished) {
      duration <- finished$testStepResult$duration
      duration$seconds * 1000 + duration$nanos / 1e6
    })
    sum(unlist(durations))
  }
  # Each finished test run hook, with its start and the hook, in the order
  # they finished
  q$test_run_hooks <- function() {
    lapply(s$test_run_hooks_finished, \(finished) {
      started <- s$test_run_hooks_started[[finished$testRunHookStartedId]]
      list(finished = finished, started = started, hook = s$hooks[[started$hookId]])
    })
  }
  # What an attachment is attached to, like `When I open the page`, `Before`
  # or `BeforeAll`
  q$attached_to <- function(attachment) {
    if (!is.null(attachment$testRunHookStartedId)) {
      hook <- s$hooks[[s$test_run_hooks_started[[attachment$testRunHookStartedId]]$hookId]]
      return(if (hook$type == "BEFORE_TEST_RUN") "BeforeAll" else "AfterAll")
    }
    test_step <- s$test_steps[[attachment$testStepId]]
    if (is.null(test_step$pickleStepId)) {
      return(if (startsWith(s$hooks[[test_step$hookId]]$type, "BEFORE")) "Before" else "After")
    }
    pickle_step <- s$pickle_steps[[test_step$pickleStepId]]
    paste0(q$step_of(pickle_step)$keyword, pickle_step$text)
  }
  # The result of the test case's test step that is the worst, the last one
  # of them when several are, or NULL when it has no test steps
  q$most_severe_result_of <- function(test_case_started) {
    results <- lapply(s$test_steps_finished[[test_case_started$id]], \(finished) finished$testStepResult)
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
    for (finished in s$test_steps_finished[[test_case_started$id]]) {
      result <- finished$testStepResult
      pickle_step_id <- s$test_steps[[finished$testStepId]]$pickleStepId
      if (!is.null(pickle_step_id)) {
        steps <- c(steps, list(reported_step(q, s$pickle_steps[[pickle_step_id]], result)))
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
      status = tolower(q$status_of(test_case_started)),
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
index_document <- function(s, document) {
  feature <- document$feature
  walk <- function(children, rule = NULL) {
    for (child in children) {
      node <- child$background %||% child$scenario
      for (step in node$steps) s$steps[[step$id]] <- step
      if (!is.null(child$scenario)) {
        lineage <- list(document = document, feature = feature, rule = rule, scenario = node)
        s$lineages[[node$id]] <- lineage
        for (i in seq_along(node$examples)) {
          examples <- node$examples[[i]]
          for (j in seq_along(examples$tableBody)) {
            row <- examples$tableBody[[j]]
            s$lineages[[row$id]] <- c(
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

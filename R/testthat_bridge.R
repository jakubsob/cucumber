#' Report a scenario's result to testthat
#'
#' Each result with a failing status is a failure, and a hook's error is an
#' error, like an error in a test. A failed step's error is signalled last, as
#' it ends the test. A scenario that didn't fail but didn't
#' pass either is skipped with the reason of its worst result.
#'
#' Each failure is at its line of the feature file, so testthat's reporters
#' show it like the line of a failed expectation in a test file: a step's at
#' the step's line, a hook's at the scenario's.
#'
#' @keywords internal
#' @noRd
signal_scenario_result <- function(results, result, failing, pickle) {
  location <- \(result) feature_srcref(pickle, if (isTRUE(result$hook)) pickle$source_line else result$line)
  failures <- Filter(\(result) result$status %in% failing, results)
  failed_step <- Find(\(result) result$status == "failed" && !isTRUE(result$hook), failures)
  # a loop, purrr would wrap the expectations testthat signals as errors
  for (failure in failures) {
    if (identical(failure, failed_step)) next
    # The backtrace of the failure's error, not of the code that reports it
    trace <- failure$error$trace %||% empty_trace()
    if (inherits(failure$error, "cucumber_hook_error")) {
      # An error that doesn't end the test, as testthat shows an error in a test
      testthat::expectation(
        "error", paste0("Error: ", conditionMessage(failure$error)),
        srcref = location(failure), trace = trace
      )
    } else {
      testthat::fail(conditionMessage(failure$error), srcref = location(failure), trace = trace)
    }
  }
  if (!is.null(failed_step)) {
    error <- failed_step$error
    error$srcref <- location(failed_step)
    if (inherits(error, "expectation")) {
      class(error) <- setdiff(class(error), "cucumber_step_failure")
      testthat::exp_signal(error)
    } else {
      # testthat shows the class of an error of its own class, like it doesn't
      # for an error in a test
      class(error) <- setdiff(class(error), c("cucumber_step_error", "cucumber_hook_error"))
      stop(error)
    }
  }
  if (length(failures) == 0 && result$status != "passed" && !is.null(result$error)) {
    # skip_scenario() or testthat::skip() keep their condition
    skip <- if (inherits(result$error, "skip")) result$error else conditionMessage(result$error)
    skip_at(skip, location(Find(\(step) identical(step$error, result$error), results)))
  }
}

#' A line of a scenario's feature file, for testthat's reporters to show a
#' result there, like the line of an expectation in a test file. `NULL` for a
#' scenario without a feature file, which testthat shows where it finds it.
#' @keywords internal
#' @noRd
feature_srcref <- function(pickle, line = pickle$source_line) {
  if (is.null(pickle$feature_file)) {
    return(NULL)
  }
  # cli's links to the file need a character path, not an fs_path
  srcref(srcfile(as.character(pickle$feature_file)), c(line, 1L, line, 1L))
}

#' Signal a warning again at `srcref`, for testthat's reporters to show it
#' there, unless it already has a place, like a warning of a step. Called with
#' `rlang::cnd_entrace()` of the warning in its handler, so the backtrace ends
#' where it was signalled, not where it's signalled again.
#' @keywords internal
#' @noRd
warn_at <- function(cnd, srcref) {
  if (is.null(srcref) || !is.null(cnd$srcref)) {
    return(invisible())
  }
  cnd$srcref <- srcref
  warning(cnd)
  tryInvokeRestart("muffleWarning")
}

#' Skip the scenario's testthat test at `srcref`
#' @param skip A skip condition, or the message of a new one
#' @keywords internal
#' @noRd
skip_at <- function(skip, srcref) {
  if (!inherits(skip, "skip")) skip <- rlang::catch_cnd(testthat::skip(skip), "skip")
  skip$srcref <- srcref
  stop(skip)
}

#' testthat's reporter of the tests in a step, like `test_that()` in a step
#' definition: it reports them like testthat's reporter, at the line of the
#' feature file the step or hook runs for, and keeps the names of those that
#' failed, so the step fails too
#' @keywords internal
#' @noRd
NestedTestsReporter <- R6::R6Class(
  "NestedTestsReporter",
  inherit = testthat::Reporter,
  public = list(
    reporter = NULL,
    prefix = NULL,
    srcref = NULL,
    failed = character(),
    initialize = function(reporter, scenario, srcref = NULL) {
      self$reporter <- reporter
      self$.context <- reporter$.context
      # testthat formats the output of expectations, like the colours of
      # their differences, for the reporter it reports to
      for (field in c("width", "unicode", "crayon", "rstudio", "hyperlinks")) self[[field]] <- reporter[[field]]
      self$prefix <- paste0(scenario, " / ")
      self$srcref <- srcref
    },
    start_test = function(context, test) self$reporter$start_test(context, test),
    add_result = function(context, test, result) {
      if (inherits(result, c("expectation_failure", "expectation_error"))) {
        self$failed <- union(self$failed, substring(test, nchar(self$prefix) + 1))
      }
      # testthat finds the line of the test file that called run(), or none
      if (!is.null(self$srcref)) result$srcref <- self$srcref
      self$reporter$add_result(context, test, result)
    },
    end_test = function(context, test) self$reporter$end_test(context, test)
  )
)

#' Report the tests in a step to a NestedTestsReporter, until `frame` ends
#' @param srcref Where the tests are in the feature file, see `feature_srcref()`
#' @return The reporter, or `NULL` outside of a testthat test
#' @keywords internal
#' @noRd
local_nested_tests <- function(srcref = NULL, frame = parent.frame()) {
  testthat_state <- utils::getFromNamespace("the", "testthat")
  if (is.null(testthat_state$reporter) || length(testthat_state$description) == 0) {
    return(NULL)
  }
  nested <- NestedTestsReporter$new(
    testthat_state$reporter,
    paste(testthat_state$description, collapse = " / "),
    srcref
  )
  rlang::local_bindings(reporter = nested, .env = testthat_state, .frame = frame)
  nested
}

#' Run `code`, the body of a step or a hook, and fail it if a test in it
#' failed, see `local_nested_tests()`
#' @param what What runs `code`: "step" or "hook"
#' @param srcref Where the tests are in the feature file, see `feature_srcref()`
#' @keywords internal
#' @noRd
with_nested_tests <- function(code, what, srcref = NULL) {
  nested <- local_nested_tests(srcref)
  code
  if (length(nested$failed) > 0) {
    tests <- paste0("\"", nested$failed, "\"", collapse = ", ")
    testthat::fail(paste0("The test", if (length(nested$failed) > 1) "s", " ", tests, " in the ", what, " failed."))
  }
}

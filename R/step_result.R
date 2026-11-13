#' The statuses that fail a scenario. Failed and ambiguous steps always do,
#' pending and undefined steps only in strict mode. In a dry run, nothing runs,
#' so only a failure to run fails it.
#'
#' @keywords internal
#' @noRd
failing_statuses <- function(strict = TRUE, dry_run = FALSE) {
  if (dry_run) {
    return("failed")
  }
  c("failed", "ambiguous", if (strict) c("undefined", "pending"))
}

#' The worst of a scenario's results, by `STEP_STATUSES`, and its error
#'
#' @keywords internal
#' @noRd
worst_result <- function(results) {
  statuses <- vapply(results, \(result) result$status, character(1))
  status <- STEP_STATUSES[STEP_STATUSES %in% c(statuses, "passed")][[1]]
  worst <- Find(\(result) result$status == status, results)
  list(status = status, error = worst$error)
}

#' The status of a test step that ended with `error`, or passed without one: an
#' error that skips the scenario, like skip_scenario() or testthat::skip(),
#' skips it, pending() makes it pending, any other error fails it
#' @keywords internal
#' @noRd
error_status <- function(error = NULL) {
  if (is.null(error)) {
    "passed"
  } else if (inherits(error, "skip")) {
    "skipped"
  } else if (inherits(error, "cucumber_pending")) {
    "pending"
  } else {
    "failed"
  }
}

#' The result of a hook that ended with `error`, or passed without one
#' @keywords internal
#' @noRd
hook_result <- function(error = NULL) {
  if (inherits(error, "expectation_failure")) error <- variant_snapshot_hint(error)
  new_hook_result(error_status(error), error)
}

#' A hook's result, with a status of `STEP_STATUSES`
#' @keywords internal
#' @noRd
new_hook_result <- function(status, error = NULL, duration = 0) {
  list(status = rlang::arg_match0(status, STEP_STATUSES), error = error, duration = duration, hook = TRUE)
}

#' A step's result, with a status of `STEP_STATUSES`
#' @keywords internal
#' @noRd
new_step_result <- function(step, status, error = NULL, duration = 0) {
  step$status <- rlang::arg_match0(status, STEP_STATUSES)
  step$error <- error
  step$duration <- duration
  step
}

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

#' A hook that called skip_scenario() or testthat::skip() is skipped, one that
#' called pending() is pending, any other hook error fails it
#' @keywords internal
#' @noRd
hook_result <- function(error) {
  status <- if (inherits(error, "skip")) {
    "skipped"
  } else if (inherits(error, "cucumber_pending")) {
    "pending"
  } else {
    "failed"
  }
  if (inherits(error, "expectation_failure")) error <- variant_snapshot_hint(error)
  new_hook_result(status, error)
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

#' Mark a step as pending
#'
#' Call `pending()` inside a step implementation to signal that the step is not
#' yet implemented. The step is reported as pending and the rest of the
#' scenario's steps are skipped.
#'
#' A pending step fails the run, unless it's run with `strict = FALSE`, then
#' the scenario is reported as skipped. Outside of a Cucumber run `pending()`
#' skips the test like [testthat::skip()].
#'
#' This is useful when you want to write your feature files first and implement the steps later,
#' or when you want to temporarily disable a step without deleting its implementation.
#'
#' @param message A message explaining why the step is pending.
#'
#' @examples
#' given("I have {int} cucumbers in my basket", function(n, context) {
#'   pending("not yet implemented")
#' })
#'
#' @export
pending <- function(message = "TODO") {
  stop(structure(
    list(message = paste0("Reason: ", message), reason = message),
    class = c("cucumber_pending", "skip", "condition")
  ))
}

#' Mark a step as pending
#'
#' Call `pending()` in a step or a hook that isn't implemented yet. Outside of a
#' Cucumber run `pending()` skips the test like [testthat::skip()].
#'
#' @param message A message explaining why the step is pending.
#'
#' @examples
#' given("I have {int} cucumbers in my basket", function(n, context) {
#'   pending("not yet implemented")
#' })
#'
#' @eval features_rd(features = "pending_steps.feature")
#'
#' @export
pending <- function(message = "TODO") {
  stop(structure(
    list(message = paste0("Reason: ", message), reason = message),
    class = c("cucumber_pending", "skip", "condition")
  ))
}

#' Mark a step as pending
#'
#' Call `pending()` inside a step implementation to signal that the step is not
#' yet implemented. The scenario will be reported as skipped rather
#' than failed.
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
  testthat::skip(message)
}

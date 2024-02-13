#' Creates a regex from step name and a description
#'
#' Allows whitespace before and after the description
#' @keywords internal
#' @noRd
step_regex <- function(step_name, description) {
  paste0("^\\s*", step_name, " ", description, "\\s*$")
}

#' @keywords internal
#' @importFrom rlang exec
#' @importFrom checkmate assert_subset
make_step <- function(prefix) {
  function(description, implementation) {
    args <- formals(implementation)
    assert_subset("context", names(args[length(args)]))
    structure(
      list(
        description = step_regex(prefix, description),
        implementation = implementation
      ),
      class = "step"
    )
  }
}

#' Step
#'
#' @rdname step
#' @param description
#'   A description of the step.
#' @param implementation
#'   A function that will be run when the step is executed.
step <- NULL

#' @rdname step
#' @export
given <- make_step("Given")

#' @rdname step
#' @export
when <- make_step("When")

#' @rdname step
#' @export
then <- make_step("Then")

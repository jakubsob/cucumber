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
    step <- structure(
      list(
        description = step_regex(prefix, description),
        implementation = implementation
      ),
      class = "step"
    )
    register_step(step)
    invisible(step)
  }
}

#' Step
#'
#' The implementation function should always have the last parameter named `context`.
#' It holds the environment where state is stored.
#'
#' Named arguments that precede `context` are considered parameters.
#'
#' If a step has a description "I have {int} cucumbers in my basket" then the implementation
#' function should be a `function(n_cucumbers, context)`. The {int} value will be passed to
#' `n_cucumbers`, this parameter can have any name.
#'
#' If a step has a table, then the table will be passed as an argument next after inline parameters
#' and before `context`. See `inst/examples/table` how write implemntation that uses tables.
#'
#' @name step
#' @param description
#'   A description of the step.
#' @param implementation
#'   A function that will be run when the step is executed.
#'
#' @return None, funcion called for side effects.
NULL

#' @rdname step
#' @export
given <- make_step("Given")

#' @rdname step
#' @export
when <- make_step("When")

#' @rdname step
#' @export
then <- make_step("Then")

.steps <- function(...) {
  structure(list2(...), class = "steps")
}

register_step <- function(step) {
  steps <- getOption("steps", default = .steps())
  steps <- .steps(!!!steps, step)
  options(steps = steps)
  invisible(step)
}

clear_steps <- function() {
  options(steps = .steps())
}

get_steps <- function() {
  getOption("steps", default = .steps())
}

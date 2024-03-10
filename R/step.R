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
#' @importFrom checkmate assert_subset assert_string assert_function
make_step <- function(prefix) {
  function(description, implementation) {
    assert_string(description)
    assert_function(implementation)
    args <- formals(implementation)
    assert_subset("context", names(args[length(args)]))
    step <- structure(
      implementation,
      description = paste(prefix, description),
      detect = step_regex(prefix, description),
      class = c("step", class(implementation))
    )
    register_step(step)
    invisible(step)
  }
}

#' Step
#'
#' The implementation of Cucumber steps.
#
#' Make sure the description is unique for each step.
#'
#' The implementation function should always have the last parameter named \code{context}.
#' It holds the environment where state is stored.
#'
#' Named arguments that precede \code{context} are considered parameters.
#'
#' If a step has a description \code{"I have {int} cucumbers in my basket"} then the implementation
#' function should be a \code{function(n_cucumbers, context)}. The \code{{int}} value will be passed to
#' \code{n_cucumbers}, this parameter can have any name.
#'
#' If a table or a docstring is passed to a step, it will be passed as an argument next after inline parameters
#' and before \code{context}. See \code{inst/examples/table} how write implemntation that uses tables
#' or docstrings.
#'
#' @name step
#' @param description
#'   A description of the step.
#' @param implementation
#'   A function that will be run when the step is executed.
#' @return A function of class \code{step}, invisibly. Function should be called for side effects.
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

#' @importFrom rlang list2
.steps <- function(...) {
  structure(list2(...), class = "steps")
}

#' @importFrom rlang `:=`
register_step <- function(step) {
  assert_step(step)
  steps <- getOption(".cucumber_steps", default = .steps())
  steps <- .steps(!!!steps, !!attr(step, "description") := step)
  options(.cucumber_steps = steps)
  invisible(step)
}

clear_steps <- function() {
  options(.cucumber_steps = .steps())
}

get_steps <- function() {
  getOption(".cucumber_steps", default = .steps())
}

#' @importFrom checkmate assert_function assert_class assert_string
assert_step <- function(x) {
  assert_function(x)
  assert_class(x, "step")
  assert_string(attr(x, "description"))
  assert_string(attr(x, "detect"))
}

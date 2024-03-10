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

#' Define a step
#'
#' Provide a description that matches steps in feature files and the implementation function that will be run.
#'
#' @name step
#' @param description A description of the step.
#'
#' A simple version of a \href{https://github.com/cucumber/cucumber-expressions}{Cucumber expression}.
#' The description is used by the \code{cucumber::test} function to find an implementation of a step
#' from a feature file.
#' The description can contain placeholders in curly braces, e.g. \code{"I have {int} cucumbers in my basket"}.
#' If no step definition is found an error will be thrown. If multiple steps definitions for a single step
#' are found an error will be thrown. Make sure the description is unique for each step.
#'
#' @param implementation A function that will be run when the step is executed.
#' The implementation function should always have the last parameter named \code{context}.
#' It holds the environment where state should be stored to be passed to the next step.
#'
#' If a step has a description \code{"I have {int} cucumbers in my basket"} then the implementation
#' function should be a \code{function(n_cucumbers, context)}. The \code{{int}} value will be passed to
#' \code{n_cucumbers}, this parameter can have any name.
#'
#' If a table or a docstring is defined for a step, it will be passed as an argument after plceholder parameters
#' and before \code{context}. The function should be a \code{function(n_cucumbers, table, context)}.
#' See
#' \href{https://github.com/jakubsob/cucumber/blob/main/inst/examples/table/tests/testthat/steps/steps.R}{an example}
#' on how to write implementation that uses tables or docstrings.
#'
#' @examples
#' given("I have {int} cucumbers in my basket", function(n_cucumbers, context) {
#'   context$n_cucumbers <- n_cucumbers
#' })
#'
#' given("I have {int} cucumbers in my basket and a table", function(n_cucumbers, table, context) {
#'   context$n_cucumbers <- n_cucumbers
#'   context$table <- table
#' })
#'
#' when("I eat {int} cucumbers", function(n_cucumbers, context) {
#'   context$n_cucumbers <- context$n_cucumbers - n_cucumbers
#' })
#'
#' then("I should have {int} cucumbers in my basket", function(n_cucumbers, context) {
#'   expect_equal(context$n_cucumbers, n_cucumbers)
#' })
#'
#' @details
#' Placeholders in expressions are replaced with regular expressions that match values in the feature file.
#' The regular expressions are generated during runtime based on defined parameter types.
#' The expression \code{"I have {int} cucumbers in my basket"} will be converted to
#' \code{"I have [+-]?(?<![.])[:digit:]+(?![.]) cucumbers in my basket"}. The extracted value of \code{{int}}
#' will be passed to the implementation function after being transformed with \code{as.integer}.
#'
#' To define your own parameter types use \code{\link{define_parameter_type}}.
#'
#' @seealso [define_parameter_type]
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

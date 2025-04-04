#' Creates a regex from step name and a description
#'
#' Allows whitespace before and after the description
#' @keywords internal
#' @noRd
step_regex <- function(description) {
  paste0("^\\s*", description, "\\s*$")
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
      description = description,
      detect = step_regex(description),
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
#' Cucumber executes each step in a scenario one at a time, in the sequence you’ve written them in.
#' When Cucumber tries to execute a step, it looks for a matching step definition to execute.
#'
#' **Keywords are not taken into account when looking for a step definition.**
#' This means you cannot have a `Given`, `When`, `Then`, `And` or `But` step with the same text as another step.
#'
#' Cucumber considers the following steps duplicates:
#'
#' ```
#' Given there is money in my account
#' Then there is money in my account
#' ```
#'
#' This might seem like a limitation, but it forces you to come up with a less ambiguous, more clear domain language:
#'
#' ```
#' Given my account has a balance of £430
#' Then my account should have a balance of £430
#' ```
#'
#' To pass arguments, description can contain placeholders in curly braces.
#'
#' To match:
#'
#' ```
#' Given my account has a balance of £430
#' ```
#'
#' use:
#'
#' ```
#' given("my account has a balance of £{float}", function(balance, context) {
#'
#' })
#' ```
#'
#' If no step definition is found an error will be thrown.
#'
#' If multiple steps definitions for a single step are found an error will be thrown.
#'
#' @param implementation A function that will be run during test execution.
#'
#' The implementation function must always have the last parameter named `context`.
#' It holds the environment where test state can be stored to be passed to the next step.
#'
#' If a step has a description `"I have {int} cucumbers in my basket"` then the implementation
#' function should be `function(n, context)`. The `{int}` value will be passed to
#' `n`, this parameter can have any name.
#'
#' If a table or a docstring is defined for a step, it will be passed as an argument after placeholder parameters
#' and before `context`. The function should be a `function(n, table, context)`.
#' See
#' \href{https://github.com/jakubsob/cucumber/blob/main/inst/examples/table/tests/acceptance/setup-steps.R}{an example}
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
#' Regular expressions are generated during runtime based on defined parameter types.
#'
#' The expression `"I have {int} cucumbers in my basket"` will be converted to
#' `"I have [+-]?(?<![.])[:digit:]+(?![.]) cucumbers in my basket"`. The extracted value of `{int}`
#' will be passed to the implementation function after being transformed with `as.integer`.
#'
#' To define your own parameter types use \code{\link{define_parameter_type}}.
#'
#' @md
#' @seealso [define_parameter_type()]
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

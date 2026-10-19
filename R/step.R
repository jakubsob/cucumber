#' @keywords internal
#' @importFrom rlang exec
#' @importFrom checkmate assert_string assert_function
define_step <- function(description, implementation) {
  assert_string(description)
  assert_function(implementation)
  args <- names(formals(implementation))
  if (!identical(args[length(args)], "context")) {
    suggested <- paste(c(setdiff(args, "context"), "context"), collapse = ", ")
    abort(
      message = "A step definition must have `context` as its last argument.",
      body = c(i = glue("Use `function({suggested})`."))
    )
  }
  step <- structure(
    implementation,
    description = description,
    order = next_registration(),
    class = c("step", class(implementation))
  )
  register_step(step)
  invisible(step)
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
#' If no step definition is found an error will be thrown, with a snippet of a step definition to add.
#' When a value in the step matches more than one parameter type, like `5` for `{int}` and `{float}`,
#' the snippet suggests one definition per parameter type. The first one is code, the others are
#' commented out alternatives. Keep only one of them, as a step matching several definitions is an error.
#'
#' If multiple steps definitions for a single step are found an error will be thrown.
#'
#' @param implementation A function that will be run during test execution.
#'
#' The implementation function must always have the last parameter named `context`.
#' It holds the environment where test state can be stored to be passed to the next step.
#' Its `attach()`, `log()` and `link()` attach data to the report, see [attachments].
#'
#' If a step has a description `"I have {int} cucumbers in my basket"` then the implementation
#' function should be `function(n, context)`. The `{int}` value will be passed to
#' `n`, this parameter can have any name.
#'
#' If a table or a docstring is defined for a step, it will be passed as an argument after placeholder parameters
#' and before `context`. The function should be a `function(n, table, context)`.
#' A docstring is one string, with its media type (like `json` for `"""json`) in the
#' `media_type` attribute. Set the `cucumber.docstring_as_lines` option to `TRUE` to get it
#' as a character vector of lines instead, see [opts].
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
#' Descriptions are [Cucumber Expressions](https://github.com/cucumber/cucumber-expressions).
#' Text is matched literally, except for:
#'
#' | **Syntax**  | **Meaning**                                                                                   |
#' | ----------- | --------------------------------------------------------------------------------------------- |
#' | `{int}`     | A parameter, see [define_parameter_type()]. Its value is passed to the implementation.       |
#' | `{}`        | An anonymous parameter. Matches anything and passes it to the implementation as text.        |
#' | `(s)`       | Optional text. `"I have {int} cucumber(s)"` matches `I have 1 cucumber` and `I have 2 cucumbers`. |
#' | `a/b`       | Alternative words. `"I press the Enter/Return key"` matches either word.                     |
#'
#' To match `(`, `{`, `/` or a space between alternatives literally, escape it with a backslash,
#' e.g. `"a\\/b"` or `"I live in New\\ York/Boston"`. An invalid expression, like an empty optional `()` or an
#' alternative without text, is an error.
#'
#' Placeholders in expressions are replaced with regular expressions that match values in the feature file.
#' The expression `"I have {int} cucumbers in my basket"` will be converted to
#' `"^I have ((?:-?\\d+)|(?:\\d+)) cucumbers in my basket$"`. The extracted value of `{int}`
#' will be passed to the implementation function after being transformed with `as.integer`.
#'
#' # Regular expressions
#'
#' A description that starts with `^`, ends with `$` or is surrounded by `/` is a regular expression
#' instead of a Cucumber Expression. Each capture group's text is passed to the implementation, in order:
#'
#' ```
#' given("^I have (\\d+) (red|green) cucumbers?$", function(n, colour, context) {
#'
#' })
#' ```
#'
#' A capture group whose regexp is the regexp of a parameter type, like `\d+` for `{int}`, is
#' transformed by it. Other capture groups are passed as text, and `NA` when they don't match.
#' A regular expression without `^` and `$` can match a part of the step's text.
#'
#' To define your own parameter types use \code{\link{define_parameter_type}}.
#'
#' @md
#' @seealso [define_parameter_type()]
#' @return A function of class \code{step}, invisibly. Function should be called for side effects.
NULL

#' @rdname step
#' @export
given <- define_step

#' @rdname step
#' @export
when <- define_step

#' @rdname step
#' @export
then <- define_step

#' @importFrom rlang list2
.steps <- function(...) {
  structure(list2(...), class = "steps")
}

#' @importFrom rlang `:=`
register_step <- function(step) {
  assert_step(step)
  steps <- getOption(getOption(".cucumber_steps_option"), default = .steps())
  steps <- .steps(!!!steps, !!attr(step, "description") := step)
  options(list2(!!getOption(".cucumber_steps_option") := steps))
  invisible(step)
}

clear_steps <- function() {
  options(list2(!!getOption(".cucumber_steps_option") := .steps()))
}

get_steps <- function() {
  getOption(getOption(".cucumber_steps_option"), default = .steps())
}

#' @importFrom checkmate assert_function assert_class assert_string
assert_step <- function(x) {
  assert_function(x)
  assert_class(x, "step")
  assert_string(attr(x, "description"))
}

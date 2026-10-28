#' @keywords internal
#' @importFrom rlang exec
#' @importFrom checkmate assert_string assert_function
define_step <- function(description, implementation) {
  assert_string(description)
  assert_function(implementation)
  args <- names(formals(implementation))
  if (!identical(args[length(args)], "context")) {
    suggested <- paste(c(setdiff(args, "context"), "context"), collapse = ", ")
    hint <- glue("Use `function({suggested})`")
    # A last argument other than `context` may be the context under another name.
    if (length(args) > 0 && !any(c("context", "...") %in% args)) {
      hint <- glue("{hint}, or rename `{args[length(args)]}` to `context`")
    }
    abort(
      message = "A step definition must have `context` as its last argument.",
      body = c(i = glue("{hint}."))
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
#' @param description A [Cucumber Expression](https://github.com/cucumber/cucumber-expressions)
#'   or a regular expression that matches the text of steps, without their keyword.
#'   Its parameters, like `{int}`, are passed to the implementation, see [define_parameter_type()].
#'
#' @param implementation A function that gets the step's parameters, then its Data Table or
#'   Doc String, then `context`: an environment that the steps and hooks of a scenario share.
#'   Its `attach()`, `log()` and `link()` attach data to the report, see [attachments].
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
#' @eval features_rd(features = c(
#'   "cucumber_expressions.feature",
#'   "regular_expressions.feature",
#'   "r-step_definition_arguments.feature",
#'   "r-sharing_state_with_context.feature",
#'   "data_tables.feature",
#'   "doc_string.feature",
#'   "passing_steps.feature",
#'   "failing_steps.feature",
#'   "undefined_step.feature",
#'   "step_definition_snippets.feature",
#'   "ambiguous_step.feature"
#' ))
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

#' Where a definition is written: its file, line and column, or `NULL` without
#' a source reference. A file sourced again, like a setup file that testthat
#' and `test()` both run, defines the same definitions again.
#' @keywords internal
#' @noRd
definition_place <- function(srcref) {
  if (is.null(srcref)) {
    return(NULL)
  }
  srcfile <- attr(srcref, "srcfile")
  paste(fs::path_abs(srcfile$filename, srcfile$wd %||% "."), srcref[[1]], srcref[[5]])
}

#' Whether a definition is one of an earlier load of its file: written in the
#' same place, but parsed again. The definitions of one load, like by a function
#' or a loop, share their srcfile, so they are different definitions.
#' @keywords internal
#' @noRd
defined_again <- function(srcref, other) {
  place <- definition_place(srcref)
  !is.null(place) && identical(place, definition_place(other)) &&
    !identical(attr(srcref, "srcfile"), attr(other, "srcfile"))
}

#' @importFrom rlang `:=`
register_step <- function(step) {
  steps <- get_steps()
  # A step definition defined again where it's written replaces itself
  again <- vapply(steps, \(other) {
    identical(attr(other, "description"), attr(step, "description")) &&
      defined_again(attr(other, "srcref"), attr(step, "srcref"))
  }, logical(1))
  steps <- .steps(!!!steps[!again], !!attr(step, "description") := step)
  set_steps(steps)
  invisible(step)
}

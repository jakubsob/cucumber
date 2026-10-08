#' @importFrom rlang abort
#' @importFrom checkmate assert_function assert_string
make_hook <- function(kind, arguments) {
  function(hook, tags = NULL, name = NULL) {
    assert_function(hook)
    if (length(formals(hook)) != length(arguments)) {
      abort(
        message = glue("A `{kind}` hook must have {length(arguments)} arguments."),
        body = if (length(arguments) > 0) {
          c(i = glue("Use `function({paste(arguments, collapse = ', ')})`."))
        } else {
          c(i = "Use `function()`.")
        }
      )
    }
    assert_string(tags, null.ok = TRUE)
    assert_string(name, null.ok = TRUE)
    # Fail at registration on an invalid tag expression
    evaluate_tag_expression(tags, character())
    register_hook(name_hook(hook, name), kind, tags)
    invisible(hook)
  }
}

#' Skip a scenario
#'
#' Call `skip_scenario()` in a [before()] hook to skip the scenario, e.g. when
#' a service it needs isn't available. The rest of the `before` hooks and all
#' the scenario's steps are skipped, and the scenario is reported as skipped.
#' `after` hooks still run and get `"skipped"` as the scenario's `status`.
#'
#' Calling it in any other hook is an error. Outside of a Cucumber run
#' `skip_scenario()` skips the test like [testthat::skip()].
#'
#' @param message A message explaining why the scenario is skipped.
#'
#' @examples
#' before(function(context, scenario) {
#'   if (!nzchar(Sys.getenv("API_KEY"))) {
#'     skip_scenario("API_KEY is not set")
#'   }
#' }, tags = "@api")
#'
#' @export
skip_scenario <- function(message = "Skipped") {
  stop(structure(
    list(message = paste0("Reason: ", message), reason = message),
    class = c("cucumber_skip_scenario", "skip", "condition")
  ))
}

#' Prefix the errors of a named hook with its name
#' @keywords internal
#' @noRd
name_hook <- function(hook, name) {
  if (is.null(name)) {
    return(hook)
  }
  function(...) {
    tryCatch(hook(...), error = function(e) {
      e$message <- paste0("Hook \"", name, "\" failed: ", e$message)
      stop(e)
    })
  }
}

#' Hooks
#'
#' @description
#'
#' Hooks are blocks of code that can run at various points in the Cucumber execution cycle. They are typically used for setup and teardown of the environment before and after each scenario.
#'
#' Where a hook is defined has no impact on what scenarios it is run for.
#'
#' You can define any number of hooks of each kind. Before hooks run in the order they are defined, after hooks in the reverse order.
#'
#' @param hook A function that will be run.
#'
#'   - `before()` and `after()` hooks get the `context` and the `scenario`: a list with
#'     the scenario's `name`, `tags`, `uri` (the feature file),
#'     and in `after()` hooks its `status` and `error`.
#'   - `before_step()` and `after_step()` hooks get the `context` and the `step`: a list with
#'     the step's `keyword` and `text`, and in `after_step()` hooks its `status` and `error`.
#'   - `before_all()` and `after_all()` hooks get no arguments.
#'
#' @param tags A tag expression, e.g. `"@db and not @slow"`.
#'   The hook runs only for scenarios that match it. If `NULL`, it runs for every scenario.
#'
#' @param name A name for the hook, shown in its error messages, e.g. `Hook "Connect to the database" failed: ...`.
#'
#' @section Before:
#'
#' Whatever happens in a `before` hook is invisible to people who only read the features.
#' You should consider using a background as a more explicit alternative, especially if the setup should be readable by non-technical people.
#' Only use a `before` hook for low-level logic such as starting a browser or deleting data from a database.
#'
#' If a `before` hook fails, the rest of the `before` hooks and all the scenario's steps are skipped, and the scenario fails.
#'
#' If a `before` hook calls [skip_scenario()], the rest of the `before` hooks and all the scenario's steps are skipped,
#' and the scenario is skipped. `after` hooks still run and get `"skipped"` as the scenario's `status`.
#'
#' @section After:
#'
#' After hooks run after the last step of each scenario, even when the scenario failed or thrown an error.
#' A failing `after` hook fails the scenario.
#'
#' @section Step hooks:
#'
#' `before_step()` and `after_step()` hooks run before and after each step that runs.
#' They don't run for skipped, undefined or ambiguous steps.
#' If a step hook fails, the step fails.
#'
#' @section Before all and after all:
#'
#' `before_all()` hooks run once before the first scenario, `after_all()` hooks once after the last one,
#' even when the run failed.
#'
#' Hooks don't run in a dry run.
#'
#' @examples
#' \dontrun{
#' before(function(context, scenario) {
#'   context$session <- selenider::selenider_session()
#' })
#'
#' after(function(context, scenario) {
#'   if (scenario$status == "failed") {
#'     selenider::take_screenshot(file = paste0(scenario$name, ".png"))
#'   }
#'   selenider::close_session(context$session)
#' })
#'
#' before(function(context, scenario) {
#'   context$db <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
#' }, tags = "@db", name = "Connect to the database")
#'
#' before(function(context, scenario) {
#'   if (!nzchar(Sys.getenv("API_KEY"))) skip_scenario("API_KEY is not set")
#' }, tags = "@api")
#'
#' after_step(function(context, step) {
#'   message(step$text, ": ", step$status)
#' })
#'
#' before_all(function() {
#'   options(warn = 2)
#' })
#' }
#' @md
#' @name hook
NULL

#' @rdname hook
#' @export
before <- make_hook("before", c("context", "scenario"))

#' @rdname hook
#' @export
after <- make_hook("after", c("context", "scenario"))

#' @rdname hook
#' @export
before_step <- make_hook("before_step", c("context", "step"))

#' @rdname hook
#' @export
after_step <- make_hook("after_step", c("context", "step"))

#' @rdname hook
#' @export
before_all <- function(hook, name = NULL) {
  make_hook("before_all", character())(hook, name = name)
}

#' @rdname hook
#' @export
after_all <- function(hook, name = NULL) {
  make_hook("after_all", character())(hook, name = name)
}

#' @importFrom rlang list2
.hooks <- function(...) {
  structure(list2(...), class = "hooks")
}

#' @importFrom rlang `:=` list2
register_hook <- function(hook, name, tags = NULL) {
  hooks <- get_hooks()
  hooks <- structure(
    c(hooks, list(list(name = name, fn = hook, tags = tags))),
    class = "hooks"
  )
  options(list2(!!getOption(".cucumber_hooks_option") := hooks))
  invisible(hooks)
}

#' Hooks of one kind that apply to a scenario with these tags, in the order
#' they run: after hooks in the reverse order of definition
#' @keywords internal
#' @noRd
#' @importFrom purrr keep map
get_hooks_to_run <- function(hooks, name, tags = character()) {
  fns <- hooks |>
    keep(\(hook) hook$name == name && evaluate_tag_expression(hook$tags, tags)) |>
    map("fn")
  if (startsWith(name, "after")) rev(fns) else fns
}

#' Run hooks and return the first error, or NULL. Before hooks stop at the
#' first error, after hooks all run. With `can_skip`, a hook calling
#' skip_scenario() stops the hooks and its condition is returned. Otherwise
#' skip_scenario() is an error.
#' @keywords internal
#' @noRd
#' @importFrom rlang error_cnd
run_hooks <- function(fns, ..., stop_on_error = TRUE, can_skip = FALSE) {
  first_error <- NULL
  for (fn in fns) {
    error <- tryCatch(
      {
        fn(...)
        NULL
      },
      cucumber_skip_scenario = function(cnd) {
        if (can_skip) {
          return(cnd)
        }
        error_cnd(message = "`skip_scenario()` can only be called in a `before()` hook.")
      },
      error = identity
    )
    if (inherits(error, "cucumber_skip_scenario")) {
      return(error)
    }
    first_error <- first_error %||% error
    if (!is.null(error) && stop_on_error) break
  }
  first_error
}

#' @importFrom rlang list2
clear_hooks <- function() {
  options(list2(!!getOption(".cucumber_hooks_option") := .hooks()))
}

get_hooks <- function() {
  getOption(getOption(".cucumber_hooks_option"), default = .hooks())
}

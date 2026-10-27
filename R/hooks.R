#' @importFrom rlang abort
#' @importFrom checkmate assert_function assert_string
make_hook <- function(kind, arguments) {
  function(hook, tags = NULL, name = NULL) {
    assert_function(hook)
    srcref <- attr(hook, "srcref")
    # before_all and after_all hooks can leave out their context
    optional <- identical(arguments, "context")
    if (optional && length(formals(hook)) == 0) {
      fn <- hook
      hook <- function(context) fn()
    }
    if (length(formals(hook)) != length(arguments)) {
      article <- if (grepl("^[aeiou]", kind)) "An" else "A"
      abort(
        message = if (optional) {
          glue("{article} `{kind}` hook must have 0 or 1 arguments.")
        } else {
          glue("{article} `{kind}` hook must have {length(arguments)} arguments.")
        },
        body = c(i = if (optional) {
          "Use `function()` or `function(context)`."
        } else {
          glue("Use `function({paste(arguments, collapse = ', ')})`.")
        }),
        # The call of before_all() and after_all(), which call this function
        call = if (optional) rlang::caller_env() else rlang::current_env()
      )
    }
    assert_string(tags, null.ok = TRUE)
    assert_string(name, null.ok = TRUE)
    # Fail at registration on an invalid tag expression
    evaluate_tag_expression(tags, character())
    register_hook(hook, kind, tags, hook_name = name, srcref = srcref)
    invisible(hook)
  }
}

#' Skip a scenario
#'
#' Call `skip_scenario()` in a step or in a [before()] or [after()] hook to skip the
#' scenario, e.g. when a service it needs isn't available. Outside of a Cucumber run
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
#' @eval features_rd(features = "skipped_steps.feature")
#'
#' @export
skip_scenario <- function(message = "Skipped") {
  stop(structure(
    list(message = paste0("Reason: ", message), reason = message),
    class = c("cucumber_skip_scenario", "skip", "condition")
  ))
}

#' Hooks
#'
#' @description
#'
#' Hooks run code at points of a run, typically for setup and teardown: `before()` and `after()`
#' each scenario, `before_step()` and `after_step()` each step, `before_all()` and `after_all()`
#' the whole run. A `before()` or `after()` hook can skip the scenario with [skip_scenario()].
#' Hooks don't run in a dry run.
#'
#' @param hook A function that will be run.
#'
#'   - `before()` and `after()` hooks get the `context` and the `scenario`: a list with
#'     the scenario's `name`, `tags`, `uri` (the feature file), `line` (of the scenario,
#'     or of the example row of an outline) and `id`, unique in the run,
#'     and in `after()` hooks its `status` and `error`.
#'   - `before_step()` and `after_step()` hooks get the `context` and the `step`: a list with
#'     the step's `keyword`, `text`, `line`, and its `data_table` and `doc_string` if it has
#'     them, as its step definition gets them, and in `after_step()` hooks its `status` and `error`.
#'   - `before_all()` and `after_all()` hooks get no arguments, or a `context` to
#'     attach data to the report, see [attachments]. It isn't shared with scenarios.
#'
#' @param tags A tag expression, e.g. `"@db and not @slow"`.
#'   The hook runs only for scenarios that match it. If `NULL`, it runs for every scenario.
#'
#' @param name A name for the hook, shown in its error messages, e.g. `Hook "Connect to the database" failed`.
#'
#' @eval features_rd(features = c(
#'   "hooks.feature",
#'   "tagged_hooks.feature",
#'   "before_after_step_hooks.feature",
#'   "before_after_all_hooks.feature"
#' ))
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
#' # Attach a screenshot to the step that failed, see vignette("reporting")
#' after_step(function(context, step) {
#'   if (step$status == "failed") {
#'     file <- tempfile(fileext = ".png")
#'     context$app$get_screenshot(file)
#'     context$attach(readBin(file, "raw", file.size(file)), "image/png")
#'   }
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
  make_hook("before_all", "context")(hook, name = name)
}

#' @rdname hook
#' @export
after_all <- function(hook, name = NULL) {
  make_hook("after_all", "context")(hook, name = name)
}

#' @importFrom rlang list2
.hooks <- function(...) {
  structure(list2(...), class = "hooks")
}

#' @importFrom rlang `:=` list2
register_hook <- function(hook, name, tags = NULL, hook_name = NULL, srcref = NULL) {
  # A hook defined again where it's written replaces itself
  hooks <- Filter(\(other) !(other$name == name && defined_again(other$srcref, srcref)), get_hooks())
  hook <- list(
    name = name,
    fn = hook,
    tags = tags,
    hook_name = hook_name,
    srcref = srcref,
    order = next_registration()
  )
  hooks <- structure(c(hooks, list(hook)), class = "hooks")
  options(list2(!!getOption(".cucumber_hooks_option") := hooks))
  invisible(hooks)
}

#' Hooks of one kind that apply to a scenario with these tags, in the order
#' they run: after hooks in the reverse order of definition
#' @keywords internal
#' @noRd
#' @importFrom purrr keep
get_hooks_to_run <- function(hooks, name, tags = character()) {
  hooks <- keep(hooks, \(hook) hook$name == name && evaluate_tag_expression(hook$tags, tags))
  if (startsWith(name, "after")) rev(hooks) else hooks
}

#' Run hooks and return the first error, or NULL. Before hooks stop at the
#' first error, after hooks all run. With `can_skip`, a hook calling
#' skip_scenario() or testthat::skip() stops the hooks and its condition is
#' returned. Otherwise skipping is an error.
#' @param srcref Where the tests in the hooks are in the feature file, see
#'   `with_nested_tests()`
#' @param pickle The scenario the hooks run for, named in their errors, or
#'   `NULL` for before all and after all hooks
#' @keywords internal
#' @noRd
#' @importFrom rlang error_cnd
run_hooks <- function(hooks, ..., stop_on_error = TRUE, can_skip = FALSE, srcref = NULL, pickle = NULL) {
  first_error <- NULL
  for (hook in hooks) {
    error <- tryCatch(
      {
        with_nested_tests(hook$fn(...), "hook", srcref)
        NULL
      },
      cucumber_pending = function(cnd) {
        error_cnd(
          class = "cucumber_pending",
          message = glue("{hook_label(hook)} is pending: {cnd$reason}"),
          trace = empty_trace()
        )
      },
      # skip_scenario() or testthat::skip(). After cucumber_pending, as
      # pending() is a skip too
      skip = function(cnd) {
        if (can_skip) {
          return(cnd)
        }
        fn <- if (inherits(cnd, "cucumber_skip_scenario")) "skip_scenario()" else "testthat::skip()"
        hook_error(
          hook,
          error_cnd(message = glue("`{fn}` can only be called in a `before_all()`, `before()` or `after()` hook or a step.")),
          pickle
        )
      },
      error = \(e) {
        # A failed expectation is reported as it is, like in a step
        if (inherits(e, "expectation")) return(e)
        # The call a hook is run with is cucumber's, not one of the hook, like
        # `fn()` of a before all or after all hook without arguments
        if (any(vapply(list(quote(hook$fn(...)), quote(fn())), identical, logical(1), conditionCall(e)))) e$call <- NULL
        hook_error(hook, e, pickle)
      }
    )
    if (inherits(error, "skip")) {
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

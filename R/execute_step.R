#' Run a step between its before_step and after_step hooks. A failing step hook
#' fails the step, a pending one makes it pending. A failing or pending
#' before_step hook also stops the step from running.
#'
#' @keywords internal
#' @noRd
execute_step_with_hooks <- function(step, context, pickle, hooks) {
  # The step's Data Table and Doc String as its step definition gets them
  hook_step <- drop_null(list(
    keyword = step$keyword,
    text = step$text,
    line = step$line,
    data_table = step$data_table,
    doc_string = if (!is.null(step$docstring)) docstring_argument(step$docstring)
  ))
  # The tests in step hooks are at the step's line
  srcref <- feature_srcref(pickle, step$line)
  before_error <- run_step_hooks(
    get_hooks_to_run(hooks, "before_step", pickle$tags), context, hook_step,
    srcref = srcref, pickle = pickle
  )
  step <- if (is.null(before_error)) {
    execute_single_step(step, context, pickle = pickle)
  } else {
    new_step_result(step, error_status(before_error), before_error)
  }
  after_error <- run_step_hooks(
    get_hooks_to_run(hooks, "after_step", pickle$tags),
    context,
    c(hook_step, list(status = step$status, error = step$error)),
    stop_on_error = FALSE,
    srcref = srcref,
    pickle = pickle
  )
  # The step gets the worse of its own result and the hook's
  if (!is.null(after_error)) {
    worst <- worst_result(list(step, hook_result(after_error)))
    step <- new_step_result(step, worst$status, worst$error, step$duration)
  }
  step
}

#' Call a step definition or a parameter type's transformer with its arguments,
#' so that rlang captures the backtrace of an error in it from it down, see
#' `step_trace()`
#' @keywords internal
#' @noRd
call_step <- function(fn, args) {
  withr::local_options(rlang_trace_top_env = NULL)
  run <- rlang::new_function(
    rlang::pairlist2(... = ),
    bquote({
      options(rlang_trace_top_env = environment())
      .(fn)(...)
    })
  )
  exec(run, !!!args)
}

#' The backtrace of an error in a step: the calls of the step down to the
#' error, like testthat's backtrace of an error in a test starts at the calls
#' of the test's code. It's empty for an error of the step definition itself.
#' @param trace The backtrace of the error, from `rlang::cnd_entrace()` in its
#'   handler, so it ends where the error was thrown
#' @keywords internal
#' @noRd
step_trace <- function(trace) {
  # The first frame is the step definition's, see `call_step()`
  trace <- trace[-1, , drop = FALSE]
  trace$parent <- pmax(trace$parent - 1L, 0L)
  trace
}

#' Execute a single step
#'
#' @keywords internal
#' @noRd
#' @importFrom rlang error_cnd
execute_single_step <- function(step, context, pickle = NULL) {
  step_error <- NULL

  start <- Sys.time()

  tryCatch(
    withCallingHandlers(
      with_nested_tests(
        call_step(step$matched_fn, c(step$arguments(), list(context = context))),
        "step",
        feature_srcref(pickle, step$line)
      ),
      error = function(e) {
        if (
          inherits(e, "expectation") ||
            inherits(e, "cucumber_step_error")
        ) {
          return()
        }

        trace <- step_trace(rlang::cnd_entrace(e)$trace)
        rlang::abort(
          rlang::format_error_bullets(step_error_bullets(step, pickle)),
          class = "cucumber_step_error",
          parent = e,
          call = NULL,
          trace = trace
        )
      },
      # At the step's line, for testthat's reporters
      warning = \(w) warn_at(rlang::cnd_entrace(w), feature_srcref(pickle, step$line))
    ),
    cucumber_pending = function(e) {
      step_error <<- error_cnd(
        class = "cucumber_pending",
        message = glue("Step \"{step$text}\" is pending: {e$reason}"),
        trace = empty_trace()
      )
    },
    # skip_scenario() or testthat::skip() skips the step and the scenario.
    # After cucumber_pending, as pending() is a skip too
    skip = function(e) {
      step_error <<- e
    },
    expectation_failure = function(e) {
      e <- variant_snapshot_hint(e)
      e$trace <- NULL
      # Like the error of a step: which step failed, for which scenario, and
      # where it's defined, with the failed expectation as its cause
      cause <- e
      e$message <- paste0(rlang::format_error_bullets(step_error_bullets(step, pickle)), "\n", e$message)
      e$parent <- cause
      class(e) <- c("cucumber_step_failure", class(e))
      step_error <<- e
    },
    error = function(e) {
      # Keep the full cucumber_step_error for proper error reporting
      step_error <<- e
    }
  )

  new_step_result(step, error_status(step_error), step_error, seconds_since(start))
}

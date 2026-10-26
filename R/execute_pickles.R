#' Execute pickles
#'
#' @description
#' Executes a list of pickles, populating metadata (status, error, duration).
#' Each pickle runs in a testthat test_that() context.
#'
#' @param pickles List of pickle objects (must have matched steps)
#' @param hooks List of before/after hooks
#' @param reporter A CucumberReporter, or NULL
#' @param strict Whether pending and undefined steps fail the scenario
#' @param dry_run Whether to skip hooks and step bodies
#' @param fail_fast Whether to skip the scenarios after a failed scenario
#' @param retry How many times to retry a failed scenario
#' @param failed Whether a scenario of an earlier feature failed
#' @param skip The skip of a before all hook, that skips every scenario, or NULL
#' @param snapshots The snapshots of the feature, from `run_snapshots()`, or NULL
#' @return Whether a scenario failed, invisibly
#' @keywords internal
#' @noRd
#' @importFrom purrr map_chr
#' @importFrom testthat test_that
#' @importFrom rlang exec format_error_bullets
#' @importFrom glue glue
execute_pickles <- function(
  pickles,
  hooks = get_hooks(),
  reporter = NULL,
  strict = TRUE,
  dry_run = FALSE,
  fail_fast = FALSE,
  retry = 0L,
  failed = FALSE,
  skip = NULL,
  snapshots = NULL
) {
  # Named in their feature, so a scenario's name doesn't depend on which scenarios run
  test_names <- map_chr(pickles, "test_name")
  for (i in seq_along(pickles)) {
    # Skipped like in a dry run, so undefined and ambiguous steps are still reported
    pickle_failed <- execute_single_pickle(
      pickles[[i]],
      hooks,
      reporter,
      test_names[[i]],
      strict = strict,
      skip_steps = dry_run || (fail_fast && failed) || !is.null(skip),
      skip_reason = if (!is.null(skip)) conditionMessage(skip) else "A previous scenario failed and `fail_fast = TRUE`.",
      dry_run = dry_run,
      retry = retry,
      snapshots = snapshots
    )
    failed <- failed || pickle_failed
  }

  invisible(failed)
}

#' Execute a single pickle
#'
#' Every step is reported. Steps after a step that didn't pass, and all steps
#' after a failed or skipping before hook, are skipped. Steps without exactly one
#' definition are always reported as undefined or ambiguous.
#'
#' Hooks and steps are the scenario's test steps: the scenario gets the worst
#' of their results, and each after hook gets the worst result so far. Each
#' test step is reported as a message when it starts and when it finishes. Before hooks after one that didn't pass are skipped.
#'
#' With `skip_steps`, neither hooks nor step bodies run, and testthat skips the
#' scenario with `skip_reason`. In a dry run, undefined and ambiguous steps
#' don't fail the scenario either: they skip it.
#'
#' A failed scenario runs again, up to `retry` times, until it passes. Only its
#' last attempt is reported to testthat.
#'
#' @return Whether the scenario failed, invisibly
#' @keywords internal
#' @noRd
execute_single_pickle <- function(
  pickle,
  hooks,
  reporter = NULL,
  test_name = pickle$name,
  strict = TRUE,
  skip_steps = FALSE,
  skip_reason = NULL,
  dry_run = FALSE,
  retry = 0L,
  snapshots = NULL
) {
  failed <- FALSE
  # Whether a snapshot wasn't checked, as on CRAN
  snapshot_on_cran <- FALSE
  # Snapshots are named after the scenario
  if (!is.null(snapshots)) start_snapshot_scenario(snapshots, glue("Scenario: {test_name}"))
  # The reporter gets the warnings before testthat, which keeps them as its results
  test_that(glue("Scenario: {test_name}"), withCallingHandlers({
    # Errors of the scenario's steps and hooks are caught where they run. An
    # error that gets here is of cucumber itself, and stops the run.
    withCallingHandlers({
      scenario <- list(
        name = pickle$name,
        tags = paste0("@", pickle$tags),
        uri = pickle$feature_file,
        line = pickle$source_line,
        id = pickle$message$id
      )
      expectations <- 0
      # Each attempt is a test case started of its own, with a new context
      for (attempt in 0:retry) {
        if (attempt > 0 && !is.null(snapshots)) retry_snapshot_scenario(snapshots)
        # Attachments are of the test step that runs
        test_step_id <- NULL
        send <- \(attachment) {
          emit(reporter, "attachment", c(list(testCaseStartedId = test_case_started$id, testStepId = test_step_id), attachment))
        }
        test_case_started <- list(
          id = new_id(),
          testCaseId = pickle$test_case$id,
          timestamp = timestamp(),
          attempt = attempt
        )
        emit(reporter, "testCaseStarted", test_case_started)

        # The result of every test step so far: hooks and steps
        results <- list()
        # A test step that didn't pass skips the steps after it. A hook or a step
        # that skipped the scenario also skips undefined and ambiguous steps.
        skipping <- \() skip_steps || any(vapply(results, \(result) result$status != "passed", logical(1)))
        skipped <- \() any(vapply(results, \(result) result$status == "skipped" && !is.null(result$error), logical(1)))

        # Run a test step: report it as messages, and keep its result
        run_test_step <- function(id, run) {
          test_step_id <<- id
          emit(reporter, "testStepStarted", list(
            testCaseStartedId = test_case_started$id,
            testStepId = id,
            timestamp = timestamp()
          ))
          result <- run()
          emit(reporter, "testStepFinished", list(
            testCaseStartedId = test_case_started$id,
            testStepId = id,
            testStepResult = test_step_result(result),
            timestamp = timestamp()
          ))
          results <<- c(results, list(result))
        }
        run_hook <- function(test_step, skip, ...) {
          run_test_step(test_step$id, \() {
            if (skip) list(status = "skipped", duration = 0, hook = TRUE) else run_hook_step(test_step$hook, ...)
          })
        }

        with_scenario_context(send, \(.context) {
          # A dry run matches the steps, but runs neither hooks nor step bodies
          for (test_step in pickle$test_case$before) {
            run_hook(test_step, skipping(), .context, scenario, can_skip = TRUE, srcref = feature_srcref(pickle))
          }

          withCallingHandlers(for (step in pickle$steps) {
            run_test_step(step$test_step_id, \() {
              # Undefined and ambiguous steps already have a status from matching
              if (skipped()) {
                new_step_result(step, "skipped")
              } else if (!is.null(step$status)) {
                if (step$status == "undefined") emit_suggestion(reporter, step)
                step
              } else if (skipping()) {
                new_step_result(step, "skipped")
              } else {
                execute_step_with_hooks(step, .context, pickle, hooks)
              }
            })
          }, expectation = function(e) expectations <<- expectations + 1)

          for (test_step in pickle$test_case$after) {
            run_hook(test_step, skip_steps, .context, c(scenario, worst_result(results)), can_skip = TRUE, srcref = feature_srcref(pickle))
          }
        })

        result <- worst_result(results)
        # Only a failed scenario is retried: pending, undefined or ambiguous
        # steps wouldn't pass on another attempt
        retried <- result$status == "failed" && attempt < retry
        emit(reporter, "testCaseFinished", list(
          testCaseStartedId = test_case_started$id,
          timestamp = timestamp(),
          willBeRetried = retried
        ))
        if (!retried) break
      }
    }, error = \(e) if (has_restart("cucumber_abort_run")) invokeRestart("cucumber_abort_run", e))
    failing <- failing_statuses(strict, dry_run)
    failed <<- result$status %in% failing
    if (!is.null(snapshots)) end_snapshot_scenario(snapshots, result$status, snapshot_on_cran)
    signal_scenario_result(results, result, failing, pickle)
    # testthat reports a test without expectations as skipped
    if (!skip_steps && result$status == "passed" && expectations == 0) {
      testthat::succeed()
    }
    if (skip_steps && !dry_run && result$status == "skipped") {
      skip_at(skip_reason, feature_srcref(pickle))
    }
  },
    # A warning of a hook, or of what a step or a hook deferred, is at the scenario's line
    warning = \(w) {
      cucumber_event(reporter, "add_warning", w)
      warn_at(rlang::cnd_entrace(w), feature_srcref(pickle))
    },
    # Not muffled, so testthat skips the test, as it does on CRAN
    snapshot_on_cran = \(cnd) snapshot_on_cran <<- TRUE
  ))

  invisible(failed)
}

#' Run the test steps of a scenario with a new context that's the frame of a
#' function: what steps and hooks defer in it, like with
#' `withr::defer(envir = context)` or `local_mocked_bindings(.env = context)`,
#' runs when the scenario ends, after its after hooks, like at the end of a
#' testthat test. An error of what they deferred is a warning, as the
#' scenario's test steps already have their results.
#' @param send A function that reports an attachment message, see `new_context()`
#' @param run A function of the context that runs the test steps
#' @keywords internal
#' @noRd
with_scenario_context <- function(send, run) {
  ran <- FALSE
  rlang::try_fetch(
    (\() {
      run(new_context(send, environment()))
      ran <<- TRUE
    })(),
    # An error of a test step is the scenario's
    error = \(e) if (ran) warning(paste("Cleanup of the scenario failed:", conditionMessage(e)), call. = FALSE) else rlang::zap()
  )
  invisible()
}

#' Run a hook, timed. It passes, or gets the result of its error.
#' @param ... Arguments of `run_hooks()`
#' @keywords internal
#' @noRd
run_hook_step <- function(hook, ...) {
  start <- Sys.time()
  error <- run_hooks(list(hook), ...)
  result <- if (is.null(error)) list(status = "passed", hook = TRUE) else hook_result(error)
  result$duration <- seconds_since(start)
  result
}

#' Report the snippets of an undefined step
#' @keywords internal
#' @noRd
emit_suggestion <- function(reporter, step) {
  emit(reporter, "suggestion", list(
    id = new_id(),
    pickleStepId = step$id,
    snippets = lapply(step$snippets, \(code) list(language = "r", code = code))
  ))
}

#' The statuses that fail a scenario. Failed and ambiguous steps always do,
#' pending and undefined steps only in strict mode. In a dry run, nothing runs,
#' so only a failure to run fails it.
#'
#' @keywords internal
#' @noRd
failing_statuses <- function(strict = TRUE, dry_run = FALSE) {
  if (dry_run) {
    return("failed")
  }
  c("failed", "ambiguous", if (strict) c("undefined", "pending"))
}

#' The worst of a scenario's results, by `STEP_STATUSES`, and its error
#'
#' @keywords internal
#' @noRd
worst_result <- function(results) {
  statuses <- vapply(results, \(result) result$status, character(1))
  status <- STEP_STATUSES[STEP_STATUSES %in% c(statuses, "passed")][[1]]
  worst <- Find(\(result) result$status == status, results)
  list(status = status, error = worst$error)
}

#' A hook that called skip_scenario() or testthat::skip() is skipped, one that
#' called pending() is pending, any other hook error fails it
#' @keywords internal
#' @noRd
hook_result <- function(error) {
  status <- if (inherits(error, "skip")) {
    "skipped"
  } else if (inherits(error, "cucumber_pending")) {
    "pending"
  } else {
    "failed"
  }
  if (inherits(error, "expectation_failure")) error <- variant_snapshot_hint(error)
  list(status = status, error = error, hook = TRUE)
}

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
  before_error <- run_hooks(get_hooks_to_run(hooks, "before_step", pickle$tags), context, hook_step, srcref = srcref)
  step <- if (is.null(before_error)) {
    execute_single_step(step, context, pickle = pickle)
  } else {
    new_step_result(step, hook_result(before_error)$status, before_error)
  }
  after_error <- run_hooks(
    get_hooks_to_run(hooks, "after_step", pickle$tags),
    context,
    c(hook_step, list(status = step$status, error = step$error)),
    stop_on_error = FALSE,
    srcref = srcref
  )
  # The step gets the worse of its own result and the hook's
  if (!is.null(after_error)) {
    worst <- worst_result(list(step, hook_result(after_error)))
    step <- new_step_result(step, worst$status, worst$error, step$duration)
  }
  step
}

#' Report a scenario's result to testthat
#'
#' Each result with a failing status is a failure. A failed step's error is
#' signalled last, as it ends the test. A scenario that didn't fail but didn't
#' pass either is skipped with the reason of its worst result.
#'
#' Each failure is at its line of the feature file, so testthat's reporters
#' show it like the line of a failed expectation in a test file: a step's at
#' the step's line, a hook's at the scenario's.
#'
#' @keywords internal
#' @noRd
signal_scenario_result <- function(results, result, failing, pickle) {
  location <- \(result) feature_srcref(pickle, if (isTRUE(result$hook)) pickle$source_line else result$line)
  failures <- Filter(\(result) result$status %in% failing, results)
  failed_step <- Find(\(result) result$status == "failed" && !isTRUE(result$hook), failures)
  # a loop, purrr would wrap the expectations testthat signals as errors
  for (failure in failures) {
    if (identical(failure, failed_step)) next
    testthat::fail(conditionMessage(failure$error), srcref = location(failure))
  }
  if (!is.null(failed_step)) {
    error <- failed_step$error
    error$srcref <- location(failed_step)
    if (inherits(error, "expectation")) {
      # testthat's reporters show the error, not the steps, so it names the step
      error$message <- paste0("Step \"", failed_step$text, "\" failed\n", error$message)
      testthat::exp_signal(error)
    } else {
      stop(error)
    }
  }
  if (length(failures) == 0 && result$status != "passed" && !is.null(result$error)) {
    # skip_scenario() or testthat::skip() keep their condition
    skip <- if (inherits(result$error, "skip")) result$error else conditionMessage(result$error)
    skip_at(skip, location(Find(\(step) identical(step$error, result$error), results)))
  }
}

#' A line of a scenario's feature file, for testthat's reporters to show a
#' result there, like the line of an expectation in a test file. `NULL` for a
#' scenario without a feature file, which testthat shows where it finds it.
#' @keywords internal
#' @noRd
feature_srcref <- function(pickle, line = pickle$source_line) {
  if (is.null(pickle$feature_file)) {
    return(NULL)
  }
  # cli's links to the file need a character path, not an fs_path
  srcref(srcfile(as.character(pickle$feature_file)), c(line, 1L, line, 1L))
}

#' Signal a warning again at `srcref`, for testthat's reporters to show it
#' there, unless it already has a place, like a warning of a step. Called with
#' `rlang::cnd_entrace()` of the warning in its handler, so the backtrace ends
#' where it was signalled, not where it's signalled again.
#' @keywords internal
#' @noRd
warn_at <- function(cnd, srcref) {
  if (is.null(srcref) || !is.null(cnd$srcref)) {
    return(invisible())
  }
  cnd$srcref <- srcref
  warning(cnd)
  tryInvokeRestart("muffleWarning")
}

#' Skip the scenario's testthat test at `srcref`
#' @param skip A skip condition, or the message of a new one
#' @keywords internal
#' @noRd
skip_at <- function(skip, srcref) {
  if (!inherits(skip, "skip")) skip <- rlang::catch_cnd(testthat::skip(skip), "skip")
  skip$srcref <- srcref
  stop(skip)
}

new_step_result <- function(step, status, error = NULL, duration = 0) {
  step$status <- status
  step$error <- error
  step$duration <- duration
  step
}

#' Execute a single step
#'
#' @keywords internal
#' @noRd
#' @importFrom rlang error_cnd
execute_single_step <- function(step, context, pickle = NULL) {
  status <- "passed"
  step_error <- NULL

  # Capture timing
  start_time <- Sys.time()

  tryCatch(
    withCallingHandlers(
      with_nested_tests(
        exec(step$matched_fn, !!!step$arguments(), context = context),
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

        rlang::abort(
          rlang::format_error_bullets(step_error_bullets(step, pickle)),
          class = "cucumber_step_error",
          parent = e,
          call = NULL,
          trace = empty_trace()
        )
      },
      # At the step's line, for testthat's reporters
      warning = \(w) warn_at(rlang::cnd_entrace(w), feature_srcref(pickle, step$line))
    ),
    cucumber_pending = function(e) {
      status <<- "pending"
      step_error <<- error_cnd(
        class = "cucumber_pending",
        message = glue("Step \"{step$text}\" is pending: {e$reason}"),
        trace = empty_trace()
      )
    },
    # skip_scenario() or testthat::skip() skips the step and the scenario.
    # After cucumber_pending, as pending() is a skip too
    skip = function(e) {
      status <<- "skipped"
      step_error <<- e
    },
    expectation_failure = function(e) {
      e <- variant_snapshot_hint(e)
      location <- step_location(step)
      if (!is.null(location)) {
        e$message <- paste0(e$message, "\n", glue("Step at: {location}"))
      }
      e$trace <- NULL
      status <<- "failed"
      step_error <<- e
    },
    error = function(e) {
      # Keep the full cucumber_step_error for proper error reporting
      status <<- "failed"
      step_error <<- e
    }
  )

  duration <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
  new_step_result(step, status, step_error, duration)
}

#' testthat's reporter of the tests in a step, like `test_that()` in a step
#' definition: it reports them like testthat's reporter, at the line of the
#' feature file the step or hook runs for, and keeps the names of those that
#' failed, so the step fails too
#' @keywords internal
#' @noRd
NestedTestsReporter <- R6::R6Class(
  "NestedTestsReporter",
  inherit = testthat::Reporter,
  public = list(
    reporter = NULL,
    prefix = NULL,
    srcref = NULL,
    failed = character(),
    initialize = function(reporter, scenario, srcref = NULL) {
      self$reporter <- reporter
      self$.context <- reporter$.context
      # testthat formats the output of expectations, like the colours of
      # their differences, for the reporter it reports to
      for (field in c("width", "unicode", "crayon", "rstudio", "hyperlinks")) self[[field]] <- reporter[[field]]
      self$prefix <- paste0(scenario, " / ")
      self$srcref <- srcref
    },
    start_test = function(context, test) self$reporter$start_test(context, test),
    add_result = function(context, test, result) {
      if (inherits(result, c("expectation_failure", "expectation_error"))) {
        self$failed <- union(self$failed, substring(test, nchar(self$prefix) + 1))
      }
      # testthat finds the line of the test file that called run(), or none
      if (!is.null(self$srcref)) result$srcref <- self$srcref
      self$reporter$add_result(context, test, result)
    },
    end_test = function(context, test) self$reporter$end_test(context, test)
  )
)

#' Report the tests in a step to a NestedTestsReporter, until `frame` ends
#' @param srcref Where the tests are in the feature file, see `feature_srcref()`
#' @return The reporter, or `NULL` outside of a testthat test
#' @keywords internal
#' @noRd
local_nested_tests <- function(srcref = NULL, frame = parent.frame()) {
  the <- utils::getFromNamespace("the", "testthat")
  if (is.null(the$reporter) || length(the$description) == 0) {
    return(NULL)
  }
  nested <- NestedTestsReporter$new(the$reporter, paste(the$description, collapse = " / "), srcref)
  rlang::local_bindings(reporter = nested, .env = the, .frame = frame)
  nested
}

#' Run `code`, the body of a step or a hook, and fail it if a test in it
#' failed, see `local_nested_tests()`
#' @param what What runs `code`: "step" or "hook"
#' @param srcref Where the tests are in the feature file, see `feature_srcref()`
#' @keywords internal
#' @noRd
with_nested_tests <- function(code, what, srcref = NULL) {
  nested <- local_nested_tests(srcref)
  code
  if (length(nested$failed) > 0) {
    tests <- paste0("\"", nested$failed, "\"", collapse = ", ")
    testthat::fail(paste0("The test", if (length(nested$failed) > 1) "s", " ", tests, " in the ", what, " failed."))
  }
}

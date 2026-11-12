#' Execute a scenario's pickle
#'
#' Every step is reported. Steps after a step that didn't pass, and all steps
#' after a failed or skipping before hook, are skipped. Steps without exactly one
#' definition are reported as undefined or ambiguous, unless a hook or step
#' skipped the scenario.
#'
#' Hooks and steps are the scenario's test steps: the scenario gets the worst
#' of their results, and each after hook gets the worst result so far. Each
#' test step is reported as a message when it starts and when it finishes.
#' Before hooks after one that didn't pass are skipped.
#'
#' In a dry run, a before all hook that skipped, or after a failed scenario
#' with `fail_fast`, neither hooks nor step bodies run, and testthat skips the
#' scenario with the reason, except in a dry run. In a dry run, undefined and
#' ambiguous steps don't fail the scenario either: they skip it.
#'
#' A failed scenario runs again, up to `retry` times, until it passes. Only its
#' last attempt is reported to testthat.
#'
#' @param run The run, from `new_run()`
#' @param failed Whether an earlier scenario of the run failed
#' @return Whether the scenario failed, invisibly
#' @keywords internal
#' @noRd
#' @importFrom testthat test_that
#' @importFrom glue glue
#' @importFrom rlang exec format_error_bullets
execute_scenario <- function(pickle, run, failed = FALSE, test_name = pickle$name) {
  skip_reason <- if (!is.null(run$skip)) {
    conditionMessage(run$skip)
  } else if (run$config$fail_fast && failed) {
    "A previous scenario failed and `fail_fast = TRUE`."
  }
  # Skipped like in a dry run, so undefined and ambiguous steps are still reported
  skip_steps <- run$config$dry_run || !is.null(skip_reason)

  # What the scenario's attempts change as they run, and its report reads
  state <- new.env(parent = emptyenv())
  state$failed <- FALSE
  # Whether a snapshot wasn't checked, as on CRAN
  state$snapshot_on_cran <- FALSE
  # Snapshots are named after the scenario
  if (!is.null(run$snapshots)) run$snapshots$start(glue("Scenario: {test_name}"))
  test_that(glue("Scenario: {test_name}"), {
    run_scenario(state, pickle, run, skip_steps)
    report_scenario(state, pickle, run$config, skip_steps, skip_reason)
  })

  invisible(state$failed)
}

#' Run a scenario's attempts. Its warnings and passed expectations are held in
#' `state`, for `report_scenario()` to report those of the last attempt.
#' @param state The scenario's state, see `execute_scenario()`
#' @keywords internal
#' @noRd
run_scenario <- function(state, pickle, run, skip_steps) {
  config <- run$config
  reporter <- config$reporter
  withCallingHandlers({
    # Errors of the scenario's steps and hooks are caught where they run. An
    # error that gets here is of cucumber itself, and stops the run.
    withCallingHandlers({
      scenario <- new_scenario(list(
        name = pickle$name,
        tags = paste0("@", pickle$tags, recycle0 = TRUE),
        uri = pickle$feature_file,
        line = pickle$source_line,
        id = pickle$message$id
      ))
      # Each attempt is a test case started of its own, with a new context
      for (attempt in 0:config$retry) {
        if (attempt > 0 && !is.null(run$snapshots)) run$snapshots$retry()
        # testthat gets the warnings and passed expectations of the last attempt only
        state$held <- list()
        state$expectations <- 0
        test_case_started <- list(
          id = new_id(),
          testCaseId = pickle$test_case$id,
          timestamp = timestamp(),
          attempt = attempt
        )
        emit(reporter, "testCaseStarted", test_case_started)
        run_test_steps(state, test_case_started$id, pickle, run, scenario, skip_steps)
        state$result <- worst_result(state$results)
        # Only a failed scenario is retried: pending, undefined or ambiguous
        # steps wouldn't pass on another attempt
        retried <- state$result$status == "failed" && attempt < config$retry
        emit(reporter, "testCaseFinished", list(
          testCaseStartedId = test_case_started$id,
          timestamp = timestamp(),
          willBeRetried = retried
        ))
        if (!retried) break
      }
    }, error = \(e) if (!is.null(findRestart("cucumber_abort_run"))) invokeRestart("cucumber_abort_run", e))
    state$failed <- state$result$status %in% failing_statuses(config$strict, config$dry_run)
    if (!is.null(run$snapshots)) run$snapshots$end(state$result$status, state$snapshot_on_cran)
  },
  # The reporter gets a warning as it's raised. A warning of a hook, or of
  # what a step or a hook deferred, is at the scenario's line.
  warning = \(w) {
    cucumber_event(reporter, "add_warning", w)
    if (is.null(w$srcref)) {
      w <- rlang::cnd_entrace(w)
      w$srcref <- feature_srcref(pickle)
    }
    state$held <- c(state$held, list(w))
    tryInvokeRestart("muffleWarning")
  },
  expectation_success = \(e) {
    state$held <- c(state$held, list(e))
    tryInvokeRestart("muffle_expectation")
  },
  # Not muffled, so testthat skips the test, as it does on CRAN
  snapshot_on_cran = \(cnd) state$snapshot_on_cran <- TRUE
  )
}

#' Run the test steps of an attempt of a scenario: its hooks and steps. Each is
#' reported as a message when it starts and when it finishes, and its result
#' kept in `state$results`. The steps' expectations are counted in
#' `state$expectations`.
#' @param state The scenario's state, see `execute_scenario()`
#' @param run The run, from `new_run()`
#' @param scenario The scenario as its hooks get it
#' @keywords internal
#' @noRd
run_test_steps <- function(state, test_case_started_id, pickle, run, scenario, skip_steps) {
  reporter <- run$config$reporter
  state$results <- list()
  # Attachments are of the test step that runs
  state$test_step_id <- NULL
  send <- \(attachment) {
    emit(reporter, "attachment", c(
      list(testCaseStartedId = test_case_started_id, testStepId = state$test_step_id),
      attachment
    ))
  }
  # A test step that didn't pass skips the steps after it. A hook or a step
  # that skipped the scenario also skips undefined and ambiguous steps.
  skipping <- \() skip_steps || any(vapply(state$results, \(result) result$status != "passed", logical(1)))
  skipped <- \() any(vapply(state$results, \(result) result$status == "skipped" && !is.null(result$error), logical(1)))

  # Run a test step: report it as messages, and keep its result
  run_test_step <- function(id, run) {
    state$test_step_id <- id
    emit(reporter, "testStepStarted", list(
      testCaseStartedId = test_case_started_id,
      testStepId = id,
      timestamp = timestamp()
    ))
    result <- run()
    emit(reporter, "testStepFinished", list(
      testCaseStartedId = test_case_started_id,
      testStepId = id,
      testStepResult = test_step_result(result),
      timestamp = timestamp()
    ))
    state$results <- c(state$results, list(result))
  }
  run_hook <- function(test_step, skip, ...) {
    run_test_step(test_step$id, \() {
      if (skip) new_hook_result("skipped") else run_hook_step(test_step$hook, ...)
    })
  }

  with_scenario_context(send, \(.context) {
    # A dry run matches the steps, but runs neither hooks nor step bodies
    for (test_step in pickle$test_case$before) {
      run_hook(
        test_step, skipping(), .context, scenario,
        can_skip = TRUE, srcref = feature_srcref(pickle), pickle = pickle
      )
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
          execute_step_with_hooks(step, .context, pickle, run$hooks)
        }
      })
    }, expectation = \(e) state$expectations <- state$expectations + 1)

    for (test_step in pickle$test_case$after) {
      run_hook(
        test_step, skip_steps, .context, new_scenario(c(scenario, worst_result(state$results))),
        can_skip = TRUE, srcref = feature_srcref(pickle), pickle = pickle
      )
    }
  })
}

#' The scenario that before and after hooks get, see `before()`
#' @param fields Its fields, in after hooks with its `status` and `error`
#' @keywords internal
#' @noRd
new_scenario <- function(fields) {
  structure(unclass(fields), class = "cucumber_scenario")
}

#' @export
print.cucumber_scenario <- function(x, ...) {
  status <- if (!is.null(x$status)) paste0(" ", x$status)
  cat("<scenario> \"", x$name, "\" (", x$uri, ":", x$line, ")", status, "\n", sep = "")
  if (!is.null(x$error)) cat(conditionMessage(x$error), "\n", sep = "")
  invisible(x)
}

#' Report a scenario's last attempt to testthat: its warnings and passed
#' expectations, then its result
#' @param state The scenario's state, see `execute_scenario()`
#' @keywords internal
#' @noRd
report_scenario <- function(state, pickle, config, skip_steps, skip_reason) {
  for (cnd in state$held) {
    if (inherits(cnd, "warning")) warning(cnd) else testthat::exp_signal(cnd)
  }
  signal_scenario_result(state$results, state$result, failing_statuses(config$strict, config$dry_run), pickle)
  # testthat reports a test without expectations as skipped
  if (!skip_steps && state$result$status == "passed" && state$expectations == 0) {
    testthat::succeed()
  }
  if (skip_steps && !config$dry_run && state$result$status == "skipped") {
    skip_at(skip_reason, feature_srcref(pickle))
  }
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
    error = \(e) {
      if (!ran) return(rlang::zap())
      warning(paste("Cleanup of the scenario failed:", conditionMessage(e)), call. = FALSE)
    }
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
  result <- if (is.null(error)) new_hook_result("passed") else hook_result(error)
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

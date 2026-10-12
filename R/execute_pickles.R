#' Execute pickles
#'
#' @description
#' Executes a list of pickles, populating metadata (status, error, duration).
#' Each pickle runs in a testthat test_that() context.
#'
#' @param pickles List of pickle objects (must have matched steps)
#' @param hooks List of before/after hooks
#' @param reporter Optional reporter instance (testthat::Reporter or CucumberReporter)
#' @param feature_name Optional feature name for reporter context
#' @param strict Whether pending and undefined steps fail the scenario
#' @param dry_run Whether to skip hooks and step bodies
#' @param fail_fast Whether to skip the scenarios after a failed scenario
#' @param failed Whether a scenario of an earlier feature failed
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
  feature_name = NULL,
  strict = TRUE,
  dry_run = FALSE,
  fail_fast = FALSE,
  failed = FALSE
) {
  # Call feature start hook if reporter supports it
  if (inherits(reporter, "CucumberReporter")) {
    if (!is.null(feature_name)) {
      reporter$start_feature(feature_name)
    }
  }

  test_names <- unique_test_names(map_chr(pickles, "name"))
  for (i in seq_along(pickles)) {
    # Skipped like in a dry run, so undefined and ambiguous steps are still reported
    pickle_failed <- execute_single_pickle(
      pickles[[i]],
      hooks,
      reporter,
      test_names[[i]],
      strict = strict,
      skip_steps = dry_run || (fail_fast && failed),
      dry_run = dry_run
    )
    failed <- failed || pickle_failed
  }

  # Call feature end hook if reporter supports it
  if (inherits(reporter, "CucumberReporter")) {
    reporter$end_feature()
  }

  invisible(failed)
}

#' Number the scenarios that share a name, like the rows of an outline without
#' placeholders in its name. testthat merges the results of tests that have the
#' same name.
#'
#' @keywords internal
#' @noRd
unique_test_names <- function(names) {
  repeated <- names %in% names[duplicated(names)]
  occurrence <- vapply(seq_along(names), \(i) sum(names[seq_len(i)] == names[[i]]), integer(1))
  names[repeated] <- paste0(names[repeated], " (", occurrence[repeated], ")")
  names
}

#' Execute a single pickle
#'
#' Every step is reported. Steps after a step that didn't pass, and all steps
#' after a failed or skipping before hook, are skipped. Steps without exactly one
#' definition are always reported as undefined or ambiguous.
#'
#' Like in cucumber-js, hooks and steps are the scenario's test steps: the
#' scenario gets the worst of their results, and each after hook gets the worst
#' result so far.
#'
#' With `skip_steps`, neither hooks nor step bodies run. In a dry run, undefined and
#' ambiguous steps don't fail the scenario either: they skip it.
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
  dry_run = FALSE
) {
  failed <- FALSE
  test_that(glue("Scenario: {test_name}"), {
    .context <- new.env()
    scenario <- list(name = pickle$name, tags = paste0("@", pickle$tags), uri = pickle$feature_file)
    # The results of the steps and of the hooks that didn't pass
    results <- list()
    add_hook_result <- function(error) {
      if (is.null(error)) return()
      result <- hook_result(error)
      if (inherits(reporter, "CucumberReporter") && result$status != "skipped") {
        reporter$end_hook(result$status, result$error)
      }
      results <<- c(results, list(result))
    }

    # A dry run matches the steps, but runs neither hooks nor step bodies
    if (!skip_steps) {
      add_hook_result(run_hooks(
        get_hooks_to_run(hooks, "before", pickle$tags),
        .context,
        scenario,
        can_skip = TRUE
      ))
    }

    # A failed, pending or skipping before hook skips the steps
    skipping <- skip_steps || length(results) > 0
    expectations <- 0
    withCallingHandlers(for (step in pickle$steps) {
      if (inherits(reporter, "CucumberReporter")) {
        reporter$start_step(step)
      }
      # Undefined and ambiguous steps already have a status from matching
      if (is.null(step$status)) {
        step <- if (skipping) {
          new_step_result(step, "skipped")
        } else {
          execute_step_with_hooks(step, .context, pickle, hooks)
        }
      }
      if (inherits(reporter, "CucumberReporter")) {
        reporter$end_step(step)
      }
      skipping <- skipping || step$status != "passed"
      results <- c(results, list(step))
    }, expectation = function(e) expectations <<- expectations + 1)

    if (!skip_steps) {
      for (fn in get_hooks_to_run(hooks, "after", pickle$tags)) {
        add_hook_result(run_hooks(list(fn), .context, c(scenario, worst_result(results))))
      }
    }

    result <- worst_result(results)
    if (inherits(reporter, "CucumberReporter")) {
      reporter$end_scenario(result$status)
    }
    failing <- failing_statuses(strict, dry_run)
    failed <<- result$status %in% failing
    signal_scenario_result(results, result, failing)
    # testthat reports a test without expectations as skipped
    if (!skip_steps && result$status == "passed" && expectations == 0) {
      testthat::succeed()
    }
  })

  invisible(failed)
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
  list(status = status, error = error, hook = TRUE)
}

#' Run a step between its before_step and after_step hooks. A failing step hook
#' fails the step, a pending one makes it pending. A failing or pending
#' before_step hook also stops the step from running.
#'
#' @keywords internal
#' @noRd
execute_step_with_hooks <- function(step, context, pickle, hooks) {
  hook_step <- list(keyword = step$keyword, text = step$text)
  before_error <- run_hooks(get_hooks_to_run(hooks, "before_step", pickle$tags), context, hook_step)
  step <- if (is.null(before_error)) {
    execute_single_step(step, context, pickle = pickle)
  } else {
    new_step_result(step, hook_result(before_error)$status, before_error)
  }
  after_error <- run_hooks(
    get_hooks_to_run(hooks, "after_step", pickle$tags),
    context,
    c(hook_step, list(status = step$status, error = step$error)),
    stop_on_error = FALSE
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
#' @keywords internal
#' @noRd
signal_scenario_result <- function(results, result, failing) {
  failures <- Filter(\(result) result$status %in% failing, results)
  failed_step <- Find(\(result) result$status == "failed" && !isTRUE(result$hook), failures)
  # a loop, purrr would wrap the expectations testthat signals as errors
  for (failure in failures) {
    if (identical(failure, failed_step)) next
    testthat::fail(conditionMessage(failure$error))
  }
  if (!is.null(failed_step)) {
    if (inherits(failed_step$error, "expectation")) {
      testthat::exp_signal(failed_step$error)
    } else {
      stop(failed_step$error)
    }
  }
  if (length(failures) == 0 && result$status != "passed" && !is.null(result$error)) {
    # skip_scenario() or testthat::skip() keep their condition
    if (inherits(result$error, "skip")) stop(result$error)
    testthat::skip(conditionMessage(result$error))
  }
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
      exec(step$matched_fn, !!!step$arguments(), context = context),
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
      }
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

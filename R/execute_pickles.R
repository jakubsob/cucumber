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

    # A dry run matches the steps, but runs neither hooks nor step bodies
    before_error <- NULL
    if (!skip_steps) {
      before_error <- run_hooks(
        get_hooks_to_run(hooks, "before", pickle$tags),
        .context,
        scenario,
        can_skip = TRUE
      )
    }
    # A before hook calling skip_scenario() or testthat::skip() skips the scenario
    skip <- NULL
    if (inherits(before_error, "skip")) {
      skip <- before_error
      before_error <- NULL
    }
    skipped <- !is.null(skip)

    skipping <- skip_steps || skipped || !is.null(before_error)
    steps <- list()
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
      steps <- c(steps, list(step))
    }, expectation = function(e) expectations <<- expectations + 1)

    after_error <- NULL
    if (!skip_steps) {
      scenario <- c(scenario, scenario_result(steps, before_error))
      after_error <- run_hooks(
        get_hooks_to_run(hooks, "after", pickle$tags),
        .context,
        scenario,
        stop_on_error = FALSE
      )
    }

    hook_errors <- Filter(Negate(is.null), list(before_error, after_error))
    if (inherits(reporter, "CucumberReporter")) {
      for (error in hook_errors) reporter$end_hook(hook_status(error), error)
    }
    # A pending hook counts like a pending step
    pending_hooks <- lapply(
      Filter(\(error) inherits(error, "cucumber_pending"), hook_errors),
      \(error) list(status = "pending", error = error)
    )
    hook_errors <- Filter(\(error) !inherits(error, "cucumber_pending"), hook_errors)
    failed <<- length(hook_errors) > 0 || (!dry_run && scenario_failed(c(pending_hooks, steps), strict))
    # Recorded as failures without stopping, so failed steps are reported too.
    # An "error" expectation would be recorded twice by testthat.
    for (error in hook_errors) {
      testthat::fail(conditionMessage(error))
    }
    signal_scenario_result(c(pending_hooks, steps), strict, dry_run)
    # testthat reports a test without expectations as skipped
    passed <- all(vapply(steps, \(step) step$status == "passed", logical(1)))
    if (!skip_steps && !skipped && !failed && passed && expectations == 0) {
      testthat::succeed()
    }
    # A step calling skip_scenario() or testthat::skip() skips the scenario too
    skip <- skip %||% Find(\(step) inherits(step$error, "skip"), steps)$error
    if (!is.null(skip)) {
      stop(skip)
    }
  })

  invisible(failed)
}

#' A failed or ambiguous step fails the scenario, a pending or undefined step
#' only in strict mode
#'
#' @keywords internal
#' @noRd
scenario_failed <- function(steps, strict = TRUE) {
  failing <- c("failed", "ambiguous", if (strict) c("pending", "undefined"))
  any(vapply(steps, \(step) step$status %in% failing, logical(1)))
}

#' The status of a scenario's worst step, and its error. A failed or pending
#' before hook gives the scenario its status.
#'
#' @keywords internal
#' @noRd
scenario_result <- function(steps, before_error = NULL) {
  if (!is.null(before_error)) {
    return(list(status = hook_status(before_error), error = before_error))
  }
  statuses <- vapply(steps, \(step) step$status, character(1))
  status <- STEP_STATUSES[STEP_STATUSES %in% c(statuses, "passed")][[1]]
  worst <- Find(\(step) step$status == status, steps)
  list(status = status, error = worst$error)
}

#' A hook that called pending() is pending, any other hook error fails it
#' @keywords internal
#' @noRd
hook_status <- function(error) {
  if (inherits(error, "cucumber_pending")) "pending" else "failed"
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
    new_step_result(step, hook_status(before_error), before_error)
  }
  after_error <- run_hooks(
    get_hooks_to_run(hooks, "after_step", pickle$tags),
    context,
    c(hook_step, list(status = step$status, error = step$error)),
    stop_on_error = FALSE
  )
  if (!is.null(after_error) && step$status == "passed") {
    step <- new_step_result(step, hook_status(after_error), after_error, step$duration)
  }
  step
}

#' Report the steps that didn't pass to testthat
#'
#' Ambiguous steps always fail the scenario, pending and undefined steps only
#' in strict mode. Otherwise they skip it. In a dry run none of them fail it.
#'
#' @keywords internal
#' @noRd
#' @importFrom purrr keep
signal_scenario_result <- function(steps, strict = TRUE, dry_run = FALSE) {
  lenient <- c(if (!strict || dry_run) c("pending", "undefined"), if (dry_run) "ambiguous")
  not_run <- keep(steps, \(step) step$status %in% c("pending", "undefined", "ambiguous"))
  failing <- keep(not_run, \(step) !step$status %in% lenient)
  # a loop, purrr would wrap the expectations testthat signals as errors
  for (step in failing) {
    testthat::fail(conditionMessage(step$error))
  }

  failed <- Find(\(step) step$status == "failed", steps)
  if (!is.null(failed)) {
    if (inherits(failed$error, "expectation")) {
      testthat::exp_signal(failed$error)
    } else {
      stop(failed$error)
    }
  }

  if (is.null(failed) && length(failing) == 0 && length(not_run) > 0) {
    testthat::skip(conditionMessage(not_run[[1]]$error))
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

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
#' @return List of pickles with populated metadata
#' @keywords internal
#' @noRd
#' @importFrom purrr walk2 map_chr
#' @importFrom testthat test_that
#' @importFrom rlang exec format_error_bullets
#' @importFrom glue glue
execute_pickles <- function(
  pickles,
  hooks = get_hooks(),
  reporter = NULL,
  feature_name = NULL,
  strict = TRUE,
  dry_run = FALSE
) {
  # Call feature start hook if reporter supports it
  if (inherits(reporter, "CucumberReporter")) {
    if (!is.null(feature_name)) {
      reporter$start_feature(feature_name)
    }
  }

  test_names <- unique_test_names(map_chr(pickles, "name"))
  walk2(pickles, test_names, \(pickle, test_name) {
    execute_single_pickle(
      pickle,
      hooks,
      reporter,
      test_name,
      strict = strict,
      dry_run = dry_run
    )
  })

  # Call feature end hook if reporter supports it
  if (inherits(reporter, "CucumberReporter")) {
    reporter$end_feature()
  }

  invisible(pickles)
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
#' after a failed before hook, are skipped. Steps without exactly one
#' definition are always reported as undefined or ambiguous.
#'
#' @keywords internal
#' @noRd
execute_single_pickle <- function(
  pickle,
  hooks,
  reporter = NULL,
  test_name = pickle$name,
  strict = TRUE,
  dry_run = FALSE
) {
  test_that(glue("Scenario: {test_name}"), {
    .context <- new.env()
    scenario <- list(name = pickle$name, tags = paste0("@", pickle$tags), uri = pickle$feature_file)

    # A dry run matches the steps, but runs neither hooks nor step bodies
    before_error <- NULL
    if (!dry_run) {
      before_error <- run_hooks(get_hooks_to_run(hooks, "before", pickle$tags), .context, scenario)
    }

    skipping <- dry_run || !is.null(before_error)
    steps <- list()
    for (step in pickle$steps) {
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
    }

    after_error <- NULL
    if (!dry_run) {
      scenario <- c(scenario, scenario_result(steps, before_error))
      after_error <- run_hooks(
        get_hooks_to_run(hooks, "after", pickle$tags),
        .context,
        scenario,
        stop_on_error = FALSE
      )
    }

    # Recorded as errors without stopping, so failed steps are reported too
    for (error in Filter(Negate(is.null), list(before_error, after_error))) {
      testthat::exp_signal(testthat::expectation("error", conditionMessage(error)))
    }
    signal_scenario_result(steps, strict)
  })

  invisible(NULL)
}

#' The status of a scenario's worst step, and its error. A failed before hook
#' fails the scenario.
#'
#' @keywords internal
#' @noRd
scenario_result <- function(steps, before_error = NULL) {
  if (!is.null(before_error)) {
    return(list(status = "failed", error = before_error))
  }
  statuses <- vapply(steps, \(step) step$status, character(1))
  status <- STEP_STATUSES[STEP_STATUSES %in% c(statuses, "passed")][[1]]
  worst <- Find(\(step) step$status == status, steps)
  list(status = status, error = worst$error)
}

#' Run a step between its before_step and after_step hooks. A failing step hook
#' fails the step, a failing before_step hook also stops the step from running.
#'
#' @keywords internal
#' @noRd
execute_step_with_hooks <- function(step, context, pickle, hooks) {
  hook_step <- list(keyword = step$keyword, text = step$text)
  before_error <- run_hooks(get_hooks_to_run(hooks, "before_step", pickle$tags), context, hook_step)
  step <- if (is.null(before_error)) {
    execute_single_step(step, context, pickle = pickle)
  } else {
    new_step_result(step, "failed", before_error)
  }
  after_error <- run_hooks(
    get_hooks_to_run(hooks, "after_step", pickle$tags),
    context,
    c(hook_step, list(status = step$status, error = step$error)),
    stop_on_error = FALSE
  )
  if (!is.null(after_error) && step$status == "passed") {
    step <- new_step_result(step, "failed", after_error, step$duration)
  }
  step
}

#' Report the steps that didn't pass to testthat
#'
#' Ambiguous steps always fail the scenario, pending and undefined steps only
#' in strict mode. Otherwise they skip it.
#'
#' @keywords internal
#' @noRd
#' @importFrom purrr keep
signal_scenario_result <- function(steps, strict = TRUE) {
  lenient <- if (strict) character(0) else c("pending", "undefined")
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

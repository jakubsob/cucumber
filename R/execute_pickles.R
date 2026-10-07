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

    # A dry run matches the steps, but runs neither hooks nor step bodies
    hook_error <- NULL
    if (!dry_run) {
      after <- get_hook(hooks, "after")
      before <- get_hook(hooks, "before")
      on.exit(after(.context, pickle$name))
      hook_error <- tryCatch(
        {
          before(.context, pickle$name)
          NULL
        },
        error = identity
      )
    }

    skipping <- dry_run || !is.null(hook_error)
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
          execute_single_step(step, .context, pickle = pickle)
        }
      }
      if (inherits(reporter, "CucumberReporter")) {
        reporter$end_step(step)
      }
      skipping <- skipping || step$status != "passed"
      steps <- c(steps, list(step))
    }

    if (!is.null(hook_error)) {
      stop(hook_error)
    }
    signal_scenario_result(steps, strict)
  })

  invisible(NULL)
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
      exec(step$matched_fn, !!!step$arguments, context = context),
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

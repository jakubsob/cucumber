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
#' @return List of pickles with populated metadata
#' @keywords internal
#' @noRd
#' @importFrom purrr walk
#' @importFrom testthat test_that
#' @importFrom rlang exec format_error_bullets
#' @importFrom glue glue
execute_pickles <- function(
  pickles,
  hooks = get_hooks(),
  reporter = NULL,
  feature_name = NULL
) {
  # Call feature start hook if reporter supports it
  if (inherits(reporter, "CucumberReporter")) {
    if (!is.null(feature_name)) {
      reporter$start_feature(feature_name)
    }
  }

  walk(pickles, \(pickle) {
    execute_single_pickle(pickle, hooks, reporter)
  })

  # Call feature end hook if reporter supports it
  if (inherits(reporter, "CucumberReporter")) {
    reporter$end_feature()
  }

  invisible(pickles)
}

#' Execute a single pickle
#'
#' @keywords internal
#' @noRd
execute_single_pickle <- function(pickle, hooks, reporter = NULL) {
  test_that(glue("Scenario: {pickle$name}"), {
    .context <- new.env()

    after <- get_hook(hooks, "after")
    before <- get_hook(hooks, "before")

    on.exit(after(.context, pickle$name))
    before(.context, pickle$name)

    for (i in seq_along(pickle$steps)) {
      step <- pickle$steps[[i]]
      cont <- execute_single_step(
        step,
        .context,
        pickle = pickle,
        reporter = reporter
      )
      # Update the step in the pickle with execution results
      pickle$steps[[i]] <- step
      if (!cont) break
    }
  })

  invisible(NULL)
}

#' Execute a single step
#'
#' @keywords internal
#' @noRd
execute_single_step <- function(step, context, pickle = NULL, reporter = NULL) {
  step_done <- FALSE
  step_error <- NULL

  # Call step start hook if reporter supports it
  if (inherits(reporter, "CucumberReporter")) {
    reporter$start_step(step)
  }

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
    expectation_failure = function(e) {
      location <- step_location(step)
      if (!is.null(location)) {
        e$message <- paste0(e$message, "\n", glue("Step at: {location}"))
      }
      e$trace <- NULL
      withRestarts(
        base::signalCondition(e),
        muffle_expectation = function() invisible(NULL)
      )
      step_done <<- TRUE
      step_error <<- e
    },
    error = function(e) {
      # Keep the full cucumber_step_error for proper error reporting
      step_error <<- e
      step_done <<- TRUE
    }
  )

  end_time <- Sys.time()
  duration <- as.numeric(difftime(end_time, start_time, units = "secs"))

  step$duration <- duration
  if (step_done) {
    step$status <- if (inherits(step_error, "expectation_failure")) {
      "failed"
    } else {
      "error"
    }
    step$error <- step_error
  } else {
    step$status <- "passed"
  }

  # Call step end hook if reporter supports it
  if (inherits(reporter, "CucumberReporter")) {
    reporter$end_step(step)
  }

  # Surface non-expectation errors to testthat so the scenario is recorded as an
  # error (expectation failures are already signalled above). end_step has run,
  # so the reporter has already shown the step before we re-raise.
  if (identical(step$status, "error")) {
    stop(step_error)
  }

  invisible(!step_done)
}

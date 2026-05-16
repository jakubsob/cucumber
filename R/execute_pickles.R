#' Execute pickles
#'
#' @description
#' Executes a list of pickles, populating metadata (status, error, duration).
#' Each pickle runs in a testthat test_that() context.
#'
#' @param pickles List of pickle objects (must have matched steps)
#' @param hooks List of before/after hooks
#' @return List of pickles with populated metadata
#' @keywords internal
#' @noRd
#' @importFrom purrr walk
#' @importFrom testthat test_that
#' @importFrom rlang exec format_error_bullets
#' @importFrom glue glue
execute_pickles <- function(
  pickles,
  hooks = get_hooks()
) {
  walk(pickles, \(pickle) {
    execute_single_pickle(pickle, hooks)
  })

  invisible(pickles)
}

#' Execute a single pickle
#'
#' @keywords internal
#' @noRd
execute_single_pickle <- function(pickle, hooks) {
  test_that(glue("Scenario: {pickle$name}"), {
    .context <- new.env()

    after <- get_hook(hooks, "after")
    before <- get_hook(hooks, "before")

    on.exit(after(.context, pickle$name))
    before(.context, pickle$name)

    for (i in seq_along(pickle$steps)) {
      step <- pickle$steps[[i]]
      cont <- execute_single_step(step, .context, pickle = pickle)
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
execute_single_step <- function(step, context, pickle = NULL) {
  step_done <- FALSE
  step_error <- NULL

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
      if (!inherits(e, "cucumber_step_error")) {
        step_error <<- e
      }
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

  invisible(!step_done)
}

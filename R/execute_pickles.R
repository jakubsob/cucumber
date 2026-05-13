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
#' @importFrom rlang exec error_cnd format_error_bullets trace_back
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

    for (step in pickle$steps) {
      execute_single_step(step, .context)
    }
  })

  invisible(NULL)
}

#' Execute a single step
#'
#' @keywords internal
#' @noRd
execute_single_step <- function(step, context) {
  start_time <- Sys.time()

  tryCatch(
    {
      withCallingHandlers(
        exec(step$matched_fn, !!!step$arguments, context = context),
        error = function(e) {
          if (inherits(e, "expectation")) {
            return()
          }

          trace <- rlang::trace_back()
          internal_pkgs <- c("cucumber", "rlang", "base", "methods")
          is_internal <- vapply(
            trace$envs,
            function(env) environmentName(topenv(env)) %in% internal_pkgs,
            logical(1)
          )
          user_trace <- if (any(!is_internal)) trace[!is_internal] else NULL

          location <- if (!is.null(step$definition_location)) {
            glue(
              "{getSrcFilename(step$definition_location)}:",
              "{getSrcLocation(step$definition_location, 'line', first = TRUE)}"
              )
            }

            cnd <- rlang::error_cnd(
              message = rlang::format_error_bullets(c(
                glue("Step \"{step$text}\" failed"),
                if (!is.null(location)) c(i = glue("Defined at: {location}"))
              )),
              parent = e,
              call = NULL,
              trace = user_trace
            )
            stop(cnd)
          }
        )

      # Update step metadata on success
      step$status <- "passed"
      step$duration <- as.numeric(difftime(
        Sys.time(),
        start_time,
        units = "secs"
      ))
    },
    error = function(e) {
      # Update step metadata on error
      step$status <- "failed"
      step$error <- e
      step$duration <- as.numeric(difftime(
        Sys.time(),
        start_time,
        units = "secs"
      ))
      stop(e)
    }
  )

  invisible(step)
}

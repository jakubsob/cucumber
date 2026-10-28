#' @importFrom rlang cnd_signal
#' @importFrom glue glue

empty_trace <- function() rlang::trace_back()[integer(0), ]

# An error of how cucumber is used, shown without the call or backtrace of cucumber code
abort_user <- function(...) abort(..., call = NULL, trace = empty_trace())

unwrap_purrr_error <- function(err) {
  parent <- err$parent
  if (inherits(parent, "purrr_error_indexed")) {
    unwrap_purrr_error(parent)
  } else {
    cnd_signal(parent)
  }
}

srcref_location <- function(src) {
  if (is.null(src)) return(NULL)
  glue(
    "{getSrcFilename(src)}:",
    "{getSrcLocation(src, 'line', first = TRUE)}"
  )
}

#' The error of a hook, like the error of a step: which hook failed, for which
#' scenario, and where it's defined, caused by the hook's error
#' @keywords internal
#' @noRd
hook_error <- function(hook, error, pickle = NULL) {
  info <- c(glue("{hook_label(hook)} failed"), scenario_bullets(pickle))
  location <- srcref_location(hook$srcref)
  if (!is.null(location))
    info <- c(info, i = glue("Hook defined at: {location}"))
  rlang::error_cnd(
    class = "cucumber_hook_error",
    message = rlang::format_error_bullets(info),
    parent = error,
    trace = empty_trace()
  )
}

#' A hook as its errors name it: by its name, or by its kind
#' @keywords internal
#' @noRd
hook_label <- function(hook) {
  if (is.null(hook$hook_name)) glue("Hook `{hook$name}()`") else glue("Hook \"{hook$hook_name}\"")
}

#' The feature and scenario an error of a step or a hook happened in, with the
#' feature at `line`, like `basket.feature:3`: the step's, or the scenario's
#' @keywords internal
#' @noRd
scenario_bullets <- function(pickle, line = pickle$source_line) {
  c(
    if (!is.null(pickle$feature_file)) {
      # Relative to the run's working directory, so feature files of the same name are told apart
      path <- as.character(fs::path_rel(pickle$feature_file, "."))
      if (length(line) == 1 && !is.na(line)) path <- glue("{path}:{line}")
      c(i = glue("Feature: {path}"))
    },
    if (!is.null(pickle$name)) c(i = glue("Scenario: {pickle$name}"))
  )
}

step_error_bullets <- function(step, pickle) {
  info <- c(glue("Step \"{step$text}\" failed"), scenario_bullets(pickle, step$line))
  location <- srcref_location(step$definition_location)
  if (!is.null(location))
    info <- c(info, i = glue("Step defined at: {location}"))
  info
}

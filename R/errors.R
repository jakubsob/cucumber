#' @importFrom rlang cnd_signal
#' @importFrom glue glue

empty_trace <- function() rlang::trace_back()[integer(0), ]
unwrap_purrr_error <- function(err) {
  parent <- err$parent
  if (inherits(parent, "purrr_error_indexed")) {
    unwrap_purrr_error(parent)
  } else {
    cnd_signal(parent)
  }
}

step_location <- function(step) {
  srcref_location(step$definition_location)
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
  info <- if (is.null(hook$hook_name)) glue("Hook `{hook$name}()` failed") else glue("Hook \"{hook$hook_name}\" failed")
  if (!is.null(pickle$feature_file))
    info <- c(info, i = glue("Feature: {feature_path(pickle$feature_file)}"))
  if (!is.null(pickle$name))
    info <- c(info, i = glue("Scenario: {pickle$name}"))
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

#' Where a feature file is, relative to the working directory of the run, like
#' `checkout/basket.feature`, so feature files of the same name are told apart
#' @keywords internal
#' @noRd
feature_path <- function(file) {
  as.character(fs::path_rel(file, "."))
}

step_error_bullets <- function(step, pickle) {
  info <- c(glue("Step \"{step$text}\" failed"))
  if (!is.null(pickle$feature_file))
    info <- c(info, i = glue("Feature: {feature_path(pickle$feature_file)}"))
  if (!is.null(pickle$name))
    info <- c(info, i = glue("Scenario: {pickle$name}"))
  location <- step_location(step)
  if (!is.null(location))
    info <- c(info, i = glue("Step defined at: {location}"))
  info
}

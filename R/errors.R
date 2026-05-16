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
  src <- step$definition_location
  if (is.null(src)) return(NULL)
  glue(
    "{getSrcFilename(src)}:",
    "{getSrcLocation(src, 'line', first = TRUE)}"
  )
}

step_error_bullets <- function(step, pickle) {
  info <- c(glue("Step \"{step$text}\" failed"))
  if (!is.null(pickle$feature_file))
    info <- c(info, i = glue("Feature: {basename(pickle$feature_file)}"))
  if (!is.null(pickle$name))
    info <- c(info, i = glue("Scenario: {pickle$name}"))
  location <- step_location(step)
  if (!is.null(location))
    info <- c(info, i = glue("Step defined at: {location}"))
  info
}

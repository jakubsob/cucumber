#' The registry of step definitions, hooks and parameter types: an environment
#' with `steps`, `hooks` and `parameters`. Definitions are registered in the
#' current one, `the$registry`, and a run uses what it holds.
#' @noRd
the <- new.env(parent = emptyenv())

#' A registry with only the built-in parameter types
#' @noRd
new_registry <- function() {
  registry <- local_registry(new.env(parent = emptyenv()))
  registry$steps <- .steps()
  registry$hooks <- .hooks()
  set_default_parameters()
  registry
}

#' Make `registry` the current one until `frame` ends. By default it's a copy of
#' the current one, so what is defined until then is cleared when it ends.
#' @return The registry
#' @keywords internal
#' @noRd
local_registry <- function(registry = copy_registry(the$registry), frame = parent.frame()) {
  previous <- the$registry
  the$registry <- registry
  withr::defer(the$registry <- previous, frame)
  invisible(registry)
}

copy_registry <- function(registry) {
  list2env(as.list(registry), new.env(parent = emptyenv()))
}

get_steps <- function() {
  the$registry$steps
}

set_steps <- function(steps) {
  the$registry$steps <- steps
}

clear_steps <- function() {
  set_steps(.steps())
}

get_hooks <- function() {
  the$registry$hooks
}

set_hooks <- function(hooks) {
  the$registry$hooks <- hooks
}

get_parameters <- function() {
  the$registry$parameters
}

set_parameters <- function(parameters) {
  the$registry$parameters <- parameters
}

cleanup <- function() {
  clear_steps()
  set_hooks(.hooks())
  set_default_parameters()
}

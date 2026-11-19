#' Say which step or hook the debugger opens in next, as its errors name it.
#' The debugger itself only shows an anonymous function. The `debug_hint` of
#' the run, a function of `what` and `bullets`, returns the lines to print.
#' @param what What the debugger opens in, like `step "I have 5 cucumbers"`
#' @param bullets Where it is, from `step_bullets()` or `hook_bullets()`
#' @param config The settings of the run, from `run_config()`, with the colors
#'   and symbols of the terminal
#' @keywords internal
#' @noRd
announce_debugger <- function(what, bullets, config) {
  # Like the reporters, as cli finds no colors while a step runs
  withr::local_options(cli.num_colors = config$num_colors, cli.unicode = config$unicode)
  lines <- config$debug_hint(what = as.character(what), bullets = bullets)
  if (length(lines)) cat(paste0(lines, "\n"), sep = "")
}

#' The default `cucumber.debug_hint`: a bold title and the bullets
#' @keywords internal
#' @noRd
default_debug_hint <- function(what, bullets) {
  rlang::format_error_bullets(c(cli::style_bold(glue("Debugging {what}")), bullets))
}

check_debug_hint <- function(x) {
  if (!is.function(x)) {
    abort_user("The `cucumber.debug_hint` option must be a function of `what` and `bullets`.")
  }
}

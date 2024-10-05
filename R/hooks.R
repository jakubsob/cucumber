#' @importFrom rlang abort
make_hook <- function(name) {
  function(hook) {
    if (length(formals(hook)) != 2) {
      abort(
        message = "Hook must have two arguments.",
        body = "The first argument is the context and the second is the scenario name."
      )
    }
    register_hook(hook, name)
    invisible(hook)
  }
}

#' Hooks
#'
#' Hooks are functions that are run before or after a scenario.
#'
#' You can define them alongside steps definitions.
#'
#' If you want to run a hook only before or after a specific scenario, use it's name to execute hook only for this scenario.
#'
#' @param hook A function that will be run. The function first argument is context and the scenario name is the second argument.

#' @examples
#' \dontrun{
#' before(function(context, scenario_name) {
#'   context$session <- selenider::selenider_session()
#' })
#'
#' after(function(context, scenario_name) {
#'   selenider::close_session(context$session)
#' })
#'
#' after(function(context, scenario_name) {
#'   if (scenario_name == "Playing one round of the game") {
#'     context$game$close()
#'   }
#' })
#' }
#' @md
#' @name hook
NULL

#' @rdname hook
#' @export
before <- make_hook("before")

#' @rdname hook
#' @export
after <- make_hook("after")

#' @importFrom rlang list2
.hooks <- function(...) {
  structure(list2(...), class = "hooks")
}

#' @importFrom rlang `:=` arg_match abort
#' @importFrom checkmate test_subset
#' @importFrom glue glue
register_hook <- function(
  hook,
  name = c("before", "after")
) {
  arg_match(name)
  hooks <- getOption(".cucumber_hooks", default = .hooks())
  if (test_subset(name, names(hooks))) {
    abort(
      message = glue("Hook '{name}' already registered."),
      body = "A hook can only be registered once."
    )
  }
  hooks <- .hooks(!!name := hook)
  options(.cucumber_hooks = hooks)
  invisible(hooks)
}

#' @importFrom purrr pluck
get_hook <- function(hooks = get_hooks(), name) {
  pluck(hooks, name, .default = function(...) { })
}

clear_hooks <- function() {
  options(.cucumber_hooks = .hooks())
}

get_hooks <- function() {
  getOption(".cucumber_hooks", default = .hooks())
}

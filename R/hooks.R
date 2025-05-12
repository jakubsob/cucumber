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
#' @description
#'
#' Hooks are blocks of code that can run at various points in the Cucumber execution cycle. They are typically used for setup and teardown of the environment before and after each scenario.
#'
#' Where a hook is defined has no impact on what scenarios it is run for.
#'
#' If you want to run a hook only before or after a specific scenario, use it's name to execute hook only for this scenario.
#'
#' @param hook A function that will be run. The function first argument is context and the scenario name is the second argument.
#'
#' @section Before:
#'
#' Whatever happens in a `before` hook is invisible to people who only read the features.
#' You should consider using a background as a more explicit alternative, especially if the setup should be readable by non-technical people.
#' Only use a `before` hook for low-level logic such as starting a browser or deleting data from a database.
#'
#' @section After:
#'
#' After hooks run after the last step of each scenario, even when the scenario failed or thrown an error.
#'
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
#' @importFrom purrr `pluck<-`
register_hook <- function(
  hook,
  name = c("before", "after")
) {
  arg_match(name)
  hooks <- getOption(getOption(".cucumber_hooks_option"), default = .hooks())
  if (test_subset(name, names(hooks))) {
    abort(
      message = glue("Hook '{name}' already registered."),
      body = "A hook can only be registered once."
    )
  }
  pluck(hooks, name) <- hook
  options(list2(!!getOption(".cucumber_hooks_option") := hooks))
  invisible(hooks)
}

#' @importFrom purrr pluck
get_hook <- function(hooks = get_hooks(), name) {
  pluck(hooks, name, .default = function(...) { })
}

#' @importFrom rlang list2
clear_hooks <- function() {
  options(list2(!!getOption(".cucumber_hooks_option") := .hooks()))
}

get_hooks <- function() {
  getOption(getOption(".cucumber_hooks_option"), default = .hooks())
}

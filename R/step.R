#' Creates a regex from step name and a description
#'
#' Allows whitespace before and after the description
#' @keywords internal
#' @noRd
step_regex <- function(step_name, description) {
  paste0("^\\s*", step_name, " ", description, "\\s*$")
}

#' @keywords internal
#' @importFrom rlang exec
make_step <- function(prefix) {
  function(description, implementation) {
    structure(
      list(
        description = step_regex(prefix, description),
        implementation = implementation
      ),
      class = "step"
    )
  }
}

given <- make_step("Given")

when <- make_step("When")

then <- make_step("Then")

#' @importFrom rlang exec
run.step <- function(step, input, context) {
  params <- extract_params(input, step$description)
  exec(
    step$implementation,
    !!!params,
    context = context
  )
}

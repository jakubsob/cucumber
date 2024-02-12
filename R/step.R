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
#' @importFrom checkmate assert_subset
make_step <- function(prefix) {
  function(description, implementation) {
    args <- formals(implementation)
    assert_subset("context", names(args[length(args)]))
    structure(
      list(
        description = step_regex(prefix, description),
        implementation = implementation
      ),
      class = "step"
    )
  }
}

#' @export
given <- make_step("Given")

#' @export
when <- make_step("When")

#' @export
then <- make_step("Then")

#' @keywords internal
#' @noRd
#' @importFrom rlang exec
run.step <- function(x, input, context) {
  params <- extract_params(input, x$description)
  exec(
    x$implementation,
    !!!params,
    context = context
  )
}

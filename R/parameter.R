#' @importFrom rlang list2
.parameters <- function(...) {
  structure(list2(...), class = "parameters")
}

#' @importFrom checkmate assert_string assert_function
.parameter <- function(name, regexp, transformer) {
  assert_string(name)
  assert_string(regexp)
  assert_function(transformer)
  structure(
    list(
      name = name,
      regexp = regexp,
      transformer = transformer
    ),
    class = "parameter"
  )
}

#' Define Parameter Type
#'
#' Add a new parameter to the list of parameters that can be used in step definitions.
#'
#' @param name
#'  The name of the parameter.
#' @param regexp
#'   A regular expression that the parameter will match on.
#' @param transformer
#'  A function that will transform the parameter from a string to the desired type.
#'  Must be a funcion that requires only a single argument.
#'
#' @examples
#' define_parameter_type("int", "\\d+", as.numeric)
#' define_parameter_type("string", "[:print:]+", as.character)
#' define_parameter_type("color", "red|blue|green", as.character)
#'
#' @export
define_parameter_type <- function(name, regexp, transformer) {
  parameters <- get_parameters()
  parameter <- .parameter(name, regexp, transformer)
  parameters <- .parameters(!!!parameters, list(parameter))
  set_parameters(parameters)
  invisible(parameter)
}

get_parameters <- function() {
  getOption("parameters", default = .parameters())
}

set_parameters <- function(parameters) {
  options(parameters = parameters)
}

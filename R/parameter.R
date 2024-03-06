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
#' define_parameter_type("color", "red|blue|green", as.character)
#' define_parameter_type("sci_number", "[+-]?\\d*\\.?\\d+(e[+-]?\\d+)?", as.numeric)
#'
#' @export
define_parameter_type <- function(name, regexp, transformer) {
  parameters <- get_parameters()
  parameter <- .parameter(name, regexp, transformer)
  parameters[[name]] <- parameter
  set_parameters(parameters)
  invisible(parameter)
}

get_parameters <- function() {
  getOption("parameters", default = .parameters())
}

set_parameters <- function(parameters) {
  options(parameters = parameters)
}

set_default_parameters <- function() {
  options(parameters = .parameters())
  define_parameter_type(
    name = "int",
    regexp = "[+-]?(?<![.])[:digit:]+(?![.])",
    transformer = as.integer
  )

  define_parameter_type(
    name = "float",
    regexp = "[+-]?[[:digit:]+]?\\.[:digit:]+",
    transformer = as.double
  )

  define_parameter_type(
    name = "string",
    regexp = "[:print:]+",
    transformer = as.character
  )
}

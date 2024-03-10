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
#' Add a new parameter that can be used in step definitions.
#'
#' @param name
#'  The name of the parameter.
#' @param regexp
#'   A regular expression that the parameter will match on. Note that if you want to escape a special character,
#'   you need to use four backslashes.
#' @param transformer
#'  A function that will transform the parameter from a string to the desired type.
#'  Must be a funcion that requires only a single argument.
#' @return An object of class \code{parameter}, invisibly. Function should be called for side effects.
#'
#' @examples
#' define_parameter_type("color", "red|blue|green", as.character)
#' define_parameter_type(
#'   name = "sci_number",
#'   regexp = "[+-]?\\\\d*\\\\.?\\\\d+(e[+-]?\\\\d+)?",
#'   transform = as.double
#' )
#' @export
define_parameter_type <- function(name, regexp, transformer) {
  parameters <- get_parameters()
  parameter <- .parameter(name, regexp, transformer)
  parameters[[name]] <- parameter
  set_parameters(parameters)
  invisible(parameter)
}

#' @importFrom purrr compact
get_parameters <- function() {
  parameters <- getOption("parameters", default = .parameters())
  c(
    parameters[c("int", "float")],
    parameters[!names(parameters) %in% c("int", "float", "string")],
    parameters[c("string")]
  ) |>
    compact()
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

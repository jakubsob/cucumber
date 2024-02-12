.parameters <- function(lst = list()) {
  structure(lst, class = "parameters")
}

.parameter <- function(name, regexp, transformer) {
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
#' @param name
#'  The name of the parameter.
#' @param regexp
#'   A regular expression that the parameter will match on.
#' @param transformer
#'  A function that will transform the parameter from a string to the desired type.
#'  Must be a funcion that requires only a single argument.
#' @export
define_parameter_type <- function(name, regexp, transformer) {
  parameters <- getOption("parameters", default = .parameters())
  parameter <- .parameter(name, regexp, transformer)
  parameters <- .parameters(append(parameters$parameters, list(parameter)))
  options(parameters = parameters)
  invisible(parameter)
}

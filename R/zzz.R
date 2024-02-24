.onLoad <- function(libname, pkgname) {
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

.onUnload <- function(libname, pkgname) {
  options(parameters = NULL)
}

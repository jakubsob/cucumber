.onLoad <- function(libname, pkgname) {
  define_parameter_type(
    name = "int",
    regexp = "[0-9]+",
    transformer = as.integer
  )

  define_parameter_type(
    name = "float",
    regexp = "[0-9]+\\.[0-9]+",
    transformer = as.double
  )

  define_parameter_type(
    name = "string",
    regexp = "[a-zA-Z]+",
    transformer = as.character
  )
}

.onUnload <- function(libname, pkgname) {
  options(parameters = NULL)
}

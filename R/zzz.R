.onLoad <- function(libname, pkgname) {
  set_default_parameters()
}

.onUnload <- function(libname, pkgname) {
  options(parameters = NULL)
}

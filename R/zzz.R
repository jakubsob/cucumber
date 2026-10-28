.onLoad <- function(libname, pkgname) {
  the$registry <- new_registry()
}

.onUnload <- function(libname, pkgname) {
}

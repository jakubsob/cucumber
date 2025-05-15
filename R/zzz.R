.onLoad <- function(libname, pkgname) {
  options(
    .cucumber_steps_option = ".cucumber_steps",
    .cucumber_hooks_option = ".cucumber_hooks",
    .cucumber_parameters_option = ".cucumber_parameters"
  )
  set_default_parameters()
}

.onUnload <- function(libname, pkgname) {
}

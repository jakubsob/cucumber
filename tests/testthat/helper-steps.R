# Register steps and parameters in an empty registry for the calling test only,
# so definitions don't leak between tests and make steps ambiguous
local_steps <- function(env = parent.frame()) {
  withr::local_options(
    .cucumber_steps_option = "test_steps",
    .cucumber_parameters_option = "test_parameters",
    test_steps = NULL,
    test_parameters = NULL,
    .local_envir = env
  )
  set_default_parameters()
}

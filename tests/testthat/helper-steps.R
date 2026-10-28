# Register steps and parameters in an empty registry for the calling test only,
# so definitions don't leak between tests and make steps ambiguous
local_steps <- function(env = parent.frame()) {
  local_registry(new_registry(), env)
}

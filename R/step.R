#' @importFrom rlang exec
step <- function(description, implementation, .feature) {
  self = attr(.feature, "self")
  definition <- find_definition(.feature, description)
  params <- extract_params(definition, description)
  exec(implementation, !!!params, context = attr(.feature, "context"))
}

given <- step

when <- step

then <- step

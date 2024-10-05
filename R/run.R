#' @importFrom purrr walk
run <- function(
  feature,
  steps,
  parameters = get_parameters(),
  hooks = get_hooks()
) {
  tokens <- tokenize(feature)
  call_queue <- parse_token(tokens, steps, parameters, hooks)
  walk(call_queue, eval)
}

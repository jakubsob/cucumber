#' @importFrom purrr walk
run <- function(
  feature,
  steps,
  parameters = get_parameters()
) {
  tokens <- tokenize(feature)
  call_queue <- parse_token(tokens, steps, parameters)
  walk(call_queue, eval)
}

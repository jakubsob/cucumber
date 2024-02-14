#' @importFrom purrr walk
run <- function(
  feature,
  steps,
  parameters = get_parameters(),
  context = new.env()
) {
  tokens <- tokenize(feature)
  call_queue <- parse_token(tokens, steps, parameters)
  walk(call_queue, \(x) x(context))
  context
}

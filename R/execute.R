#' @importFrom rlang exec
#' @importFrom purrr walk
execute <- function(
  feature,
  steps = get_steps(),
  parameters = get_parameters(),
  hooks = get_hooks()
) {
  checkmate::assert_list(steps, min.len = 1)
  checkmate::assert_list(parameters, min.len = 1)
  checkmate::assert_list(hooks)
  tokens <- tokenize(feature)
  call_queue <- parse_token(tokens, steps, parameters, hooks)
  walk(call_queue, exec)
}

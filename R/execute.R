#' @importFrom rlang exec try_fetch cnd_signal
#' @importFrom purrr walk
execute <- function(
  feature,
  steps = get_steps(),
  parameters = get_parameters(),
  hooks = get_hooks(),
  tags = NULL
) {
  checkmate::assert_list(steps, min.len = 1)
  checkmate::assert_list(parameters, min.len = 1)
  checkmate::assert_list(hooks)
  tokens <- tokenize(feature)
  call_queue <- parse_token(tokens, steps, parameters, hooks, tags)
  try_fetch(
    walk(call_queue, exec),
    purrr_error_indexed = function(err) cnd_signal(err$parent)
  )
}

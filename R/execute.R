#' @importFrom rlang exec try_fetch cnd_signal
#' @importFrom purrr walk
#' @importFrom testthat context_start_file
#' @importFrom glue glue
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

  # Phase 1: Validate
  validated <- validate_feature(feature)

  # Phase 2 & 3: Normalize and Tokenize (normalization happens inside tokenize)
  tokens <- tokenize(validated)

  # Set feature context for testthat
  if (length(tokens) > 0 && tokens[[1]]$type == "Feature") {
    context_start_file(glue("Feature: {tokens[[1]]$value}"))
  }

  # Phase 4: Create pickles
  pickles <- create_pickles(tokens)

  # Filter by tags
  pickles <- filter_pickles_by_tags(pickles, tags)

  # Phase 5: Match steps
  pickles <- match_steps(pickles, steps, parameters)

  # Phase 6: Execute
  execute_pickles(pickles, hooks)
}

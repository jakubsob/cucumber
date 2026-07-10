#' @importFrom rlang exec try_fetch cnd_signal abort
#' @importFrom checkmate test_list
#' @importFrom purrr walk map
#' @importFrom testthat context_start_file
#' @importFrom glue glue
execute <- function(
  feature,
  steps = get_steps(),
  parameters = get_parameters(),
  hooks = get_hooks(),
  tags = NULL,
  feature_file = NULL,
  reporter = NULL
) {
  if (!checkmate::test_list(steps, min.len = 1)) {
    abort(
      "No step definitions found.",
      body = c(
        i = "Define steps using `given()`, `when()`, or `then()`.",
        i = "Steps are typically placed in `setup-*.R` files and are loaded automatically by cucumber." # nolint
      ),
      trace = empty_trace()
    )
  }
  checkmate::assert_list(parameters, min.len = 1)
  checkmate::assert_list(hooks)

  # Phase 1: Validate
  validated <- validate_feature(feature)

  # Phase 2 & 3: Normalize and Tokenize (normalization happens inside tokenize)
  tokens <- tokenize(validated)

  # Extract feature name for reporter
  feature_name <- NULL
  if (length(tokens) > 0 && tokens[[1]]$type == "Feature") {
    feature_name <- glue("Feature: {tokens[[1]]$value}")
    # Set feature context for testthat
    context_start_file(feature_name)
  }

  # Phase 4: Create pickles
  pickles <- create_pickles(tokens, feature_file = feature_file)

  # Filter by tags
  pickles <- filter_pickles_by_tags(pickles, tags)

  # Phase 5: Match steps
  pickles <- match_steps(pickles, steps, parameters)

  # Phase 6: Execute
  execute_pickles(pickles, hooks, reporter = reporter, feature_name = feature_name)
}

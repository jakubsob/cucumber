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

  # Phase 1: Parse
  document <- parse_gherkin(feature, uri = feature_file)

  # An empty document has nothing to run
  if (is.null(document$feature)) {
    return(invisible(list()))
  }

  feature_name <- glue("{document$feature$keyword}: {document$feature$name}")
  # Set feature context for testthat
  context_start_file(feature_name)

  # Phase 2: Create pickles
  pickles <- create_pickles(document, feature_file = feature_file)

  # Filter by tags
  pickles <- filter_pickles_by_tags(pickles, tags)

  # Phase 3: Match steps
  pickles <- match_steps(pickles, steps, parameters)

  # Phase 4: Execute
  execute_pickles(pickles, hooks, reporter = reporter, feature_name = feature_name)
}

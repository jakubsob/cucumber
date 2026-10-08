#' @importFrom rlang exec try_fetch cnd_signal abort
#' @importFrom purrr walk map
#' @importFrom testthat context_start_file
#' @importFrom glue glue
execute <- function(
  feature,
  steps = get_steps(),
  parameters = get_parameters(),
  hooks = get_hooks(),
  tags = NULL,
  name = NULL,
  lines = integer(),
  feature_file = NULL,
  reporter = NULL,
  strict = TRUE,
  dry_run = FALSE
) {
  checkmate::assert_list(steps)
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

  # Filter by tags, name and line
  pickles <- pickles |>
    filter_pickles_by_tags(tags) |>
    filter_pickles_by_name(name) |>
    filter_pickles_by_lines(lines)

  # Phase 3: Match steps
  pickles <- match_steps(pickles, steps, parameters)

  # Phase 4: Execute
  execute_pickles(
    pickles,
    hooks,
    reporter = reporter,
    feature_name = feature_name,
    strict = strict,
    dry_run = dry_run
  )
}

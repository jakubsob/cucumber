#' Run a feature's scenarios
#'
#' @param pickles The document's pickles
#' @return Whether a scenario failed, invisibly
#' @keywords internal
#' @noRd
execute <- function(
  document,
  steps = get_steps(),
  parameters = get_parameters(),
  hooks = get_hooks(),
  tags = NULL,
  name = NULL,
  lines = integer(),
  feature_file = NULL,
  reporter = NULL,
  strict = TRUE,
  dry_run = FALSE,
  fail_fast = FALSE,
  failed = FALSE,
  pickles = create_pickles(document, feature_file = feature_file)
) {
  checkmate::assert_list(steps)
  checkmate::assert_list(parameters, min.len = 1)
  checkmate::assert_list(hooks)

  pickles <- prepare_pickles(pickles, steps, parameters, hooks, tags, name, lines, reporter)
  execute_feature(
    document,
    pickles,
    hooks,
    reporter = reporter,
    strict = strict,
    dry_run = dry_run,
    fail_fast = fail_fast,
    failed = failed
  )
}

#' Choose the pickles to run, match their steps and plan their test cases
#'
#' Each pickle that runs gets a test case, reported before any scenario runs.
#'
#' @return The pickles to run
#' @keywords internal
#' @noRd
#' @importFrom purrr map walk
prepare_pickles <- function(
  pickles,
  steps = get_steps(),
  parameters = get_parameters(),
  hooks = get_hooks(),
  tags = NULL,
  name = NULL,
  lines = integer(),
  reporter = NULL,
  test_run_started_id = NULL
) {
  pickles <- pickles |>
    filter_pickles(tags, name, lines) |>
    match_steps(steps, parameters) |>
    map(\(pickle) new_test_case(pickle, hooks))
  walk(pickles, \(pickle) emit(reporter, "testCase", test_case_message(pickle, test_run_started_id)))
  pickles
}

#' Run the prepared pickles of a feature
#'
#' @return Whether a scenario failed, invisibly
#' @keywords internal
#' @noRd
#' @importFrom testthat context_start_file
#' @importFrom glue glue
execute_feature <- function(
  document,
  pickles,
  hooks = get_hooks(),
  reporter = NULL,
  strict = TRUE,
  dry_run = FALSE,
  fail_fast = FALSE,
  failed = FALSE
) {
  # A feature without scenarios to run isn't reported
  if (length(pickles) == 0) {
    return(invisible(failed))
  }

  feature_name <- glue("{document$feature$keyword}: {document$feature$name}")
  # Set feature context for testthat
  context_start_file(feature_name)

  execute_pickles(
    pickles,
    feature_name,
    hooks,
    reporter = reporter,
    strict = strict,
    dry_run = dry_run,
    fail_fast = fail_fast,
    failed = failed
  )
}

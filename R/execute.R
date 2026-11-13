#' Plan the run's scenarios: the pickles of the features to run that are
#' selected, in the order to run them
#'
#' @param features The feature files that run
#' @param sources The parsed features by file, with their `pickles`
#' @param lines The lines of the scenarios to run of each feature file, see `feature_lines()`
#' @param config The settings of the run, from `run_config()`
#' @param glue The steps and hooks of the run, from `emit_glue()`, whose hooks
#'   are the ones to run: none in a dry run
#' @param test_run_started_id The id of the run's `testRunStarted` message
#' @return The pickles to run, each with its matched steps and its test case
#' @keywords internal
#' @noRd
#' @importFrom purrr map map_chr walk
plan_pickles <- function(features, sources, lines, config, glue, test_run_started_id) {
  # The scenarios of all features are put in order together
  pickles <- unlist(
    map(unname(features), \(path) filter_pickles(sources[[path]]$pickles, config$tags, config$name, lines[[path]])),
    recursive = FALSE
  )
  prepare_pickles(
    order_pickles(pickles, config$order),
    glue$steps,
    get_parameters(),
    glue$hooks,
    reporter = config$reporter,
    test_run_started_id = test_run_started_id
  )
}

#' Match the steps of the pickles that run and plan their test cases
#'
#' Each pickle that runs gets a test case, reported before any scenario runs.
#'
#' @return The pickles to run
#' @keywords internal
#' @noRd
prepare_pickles <- function(
  pickles,
  steps = get_steps(),
  parameters = get_parameters(),
  hooks = get_hooks(),
  reporter = NULL,
  test_run_started_id = NULL
) {
  pickles <- pickles |>
    match_steps(steps, parameters) |>
    map(\(pickle) new_test_case(pickle, hooks))
  walk(pickles, \(pickle) emit(reporter, "testCase", test_case_message(pickle, test_run_started_id)))
  pickles
}

#' What the scenarios of a run need to run: its settings and hooks, the skip of
#' a before all hook, and its snapshots
#'
#' @param config The settings of the run, from `run_config()`
#' @param hooks The hooks to run, none in a dry run
#' @param skip The skip of a before all hook, that skips every scenario, or `NULL`
#' @param snapshots The snapshots of the run, from `run_snapshots()`, or of a
#'   feature, from `local_feature_snapshots()`. By default none are kept, see
#'   `no_feature_snapshots()`.
#' @keywords internal
#' @noRd
new_run <- function(config, hooks, skip = NULL, snapshots = no_feature_snapshots()) {
  list(config = config, hooks = hooks, skip = skip, snapshots = snapshots)
}

#' Run the planned pickles, the consecutive ones of a feature in its testthat context
#'
#' @param sources The parsed features by file
#' @param start_file A function called with each feature file before its
#'   scenarios run, or `NULL`
#' @param run The run, from `new_run()`, with the snapshots of the run
#' @return Whether a scenario failed
#' @keywords internal
#' @noRd
execute_features <- function(pickles, sources, run, start_file = NULL) {
  failed <- FALSE
  files <- rle(map_chr(pickles, "feature_file"))
  for (pickles_of_feature in split(pickles, rep(seq_along(files$lengths), files$lengths))) {
    feature_file <- pickles_of_feature[[1]]$feature_file
    if (!is.null(start_file)) start_file(feature_file)
    feature_run <- run
    feature_run$snapshots <- run$snapshots$feature(feature_file, map_chr(sources[[feature_file]]$pickles, "test_name"))
    failed <- execute_feature(sources[[feature_file]]$document, pickles_of_feature, feature_run, failed)
  }
  failed
}

#' Run the prepared pickles of a feature
#'
#' Each pickle runs as a testthat test, see `execute_scenario()`.
#'
#' @param run The run, from `new_run()`, with the snapshots of the feature
#' @param failed Whether a scenario of an earlier feature failed
#' @return Whether a scenario failed, invisibly
#' @keywords internal
#' @noRd
#' @importFrom testthat context_start_file
execute_feature <- function(document, pickles, run, failed = FALSE) {
  # A feature without scenarios to run isn't reported
  if (length(pickles) == 0) {
    return(invisible(failed))
  }

  # Set feature context for testthat
  context_start_file(feature_label(document$feature))

  # expect_snapshot() saves to the feature's snapshot file
  run$snapshots$local_use()
  # Named in their feature, so a scenario's name doesn't depend on which scenarios run
  test_names <- map_chr(pickles, "test_name")
  for (i in seq_along(pickles)) {
    # Skipped like in a dry run, so undefined and ambiguous steps are still reported
    pickle_failed <- execute_scenario(pickles[[i]], run, failed, test_names[[i]])
    failed <- failed || pickle_failed
  }

  invisible(failed)
}

#' Plan the run's scenarios: the pickles of the features to run that are
#' selected, in the order to run them
#'
#' @param features The feature files that run
#' @param sources The parsed features by file, with their `pickles`
#' @param lines The lines of the scenarios to run of each feature file, see `feature_lines()`
#' @param config The settings of the run, from `run_config()`
#' @param steps The step definitions of the run, from `emit_glue()`
#' @param hooks The hooks to run, none in a dry run
#' @param test_run_started_id The id of the run's `testRunStarted` message
#' @return The pickles to run, each with its matched steps and its test case
#' @keywords internal
#' @noRd
#' @importFrom purrr map map_chr walk
plan_pickles <- function(features, sources, lines, config, steps, hooks, test_run_started_id) {
  prepare_pickles(
    select_pickles(features, sources, lines, config),
    steps,
    get_parameters(),
    hooks,
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

#' Plan a pickle's test case: its before hooks, its steps and its after hooks,
#' each with the id of its test step
#'
#' @return The pickle with its `test_case`, and its steps with their
#'   `test_step_id`
#' @noRd
#' @importFrom purrr map
new_test_case <- function(pickle, hooks) {
  hook_steps <- function(kind) {
    map(get_hooks_to_run(hooks, kind, pickle$tags), \(hook) list(id = new_id(), hook = hook))
  }
  id <- new_id()
  before <- hook_steps("before")
  pickle$steps <- map(pickle$steps, \(step) {
    step$test_step_id <- new_id()
    step
  })
  after <- hook_steps("after")
  pickle$test_case <- list(id = id, before = before, after = after)
  pickle
}

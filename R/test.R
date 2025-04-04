#' @importFrom fs dir_ls
#' @importFrom purrr map walk
run_features <- function(
  features,
  steps = get_steps(),
  parameters = get_parameters(),
  hooks = get_hooks()
) {
  features |>
    map(readLines) |>
    map(validate_feature) |>
    walk(run, steps = steps, parameters = parameters, hooks = hooks)
}

#' @importFrom fs dir_ls
find_features <- function(path) {
  dir_ls(path, glob = "*.feature$", type = "file")
}

#' @importFrom fs path_ext_remove path_file
context_name <- function(feature) {
  feature |>
    path_file() |>
    path_ext_remove()
}

filter_features <- function(features, filter = NULL, ...) {
  if (is.null(filter)) {
    return(features)
  }
  features[grepl(filter, context_name(features), ...)]
}

cleanup <- function() {
  clear_steps()
  clear_hooks()
  set_default_parameters()
}

#' @importFrom withr defer
test_cucumber_code <- function(features) {
  c(
    'withr::defer(cucumber:::cleanup(), testthat::teardown_env())',
    sprintf(
      'cucumber:::run_features(c("%s"))',
      paste(fs::path_file(features), collapse = '", "')
    )
  )
}

#' Run Cucumber tests
#'
#' It runs tests from specifications in `.feature` files found in the `path`.
#'
#' @section Good Practices:
#'
#' - Use a separate directory for your acceptance tests, e.g. `tests/acceptance`.
#'
#'   It's not prohibited to use `tests/testthat` directory, but it's not recommended as those tests
#'   serve a different purpose and are usually run separately.
#'
#' - Use [`setup-*.R`](https://testthat.r-lib.org/articles/special-files.html#setup-files)
#'   files for calling [step()], [define_parameter_type()] and [hook()] to leverage testthat loading mechanism.
#'
#'   If your [step()], [define_parameter_type()] and [hook()] are called from somewhere else, you are responsible for loading them.
#'
#'   Read more about testthat special files in the [testthat documentation](https://testthat.r-lib.org/articles/special-files.html).
#'
#' - Use `test-*.R` files to test the support code you might have implemented that is used to run Cucumber tests.
#'
#'   Those tests won't be run when calling [cucumber::test()]. To run those tests use
#'   `testthat::test_dir("tests/acceptance")`.
#'
#' @inheritParams testthat::test_dir
#' @param filter If not NULL, only features with file names matching this regular expression
#'   will be executed. Matching is performed on the file name after it's stripped of ".feature".
#'
#' @examples
#' \dontrun{
#' cucumber::test("tests/acceptance")
#' cucumber::test("tests/acceptance", filter = "addition|multiplication")
#' }
#'
#' @importFrom testthat test_dir
#' @importFrom withr defer with_file
#' @importFrom fs path
#' @importFrom checkmate test_character
#' @importFrom rlang abort
#' @export
#' @md
test <- function(
  path = "tests/acceptance",
  filter = NULL,
  reporter = NULL,
  env = NULL,
  load_helpers = TRUE,
  stop_on_failure = TRUE,
  stop_on_warning = FALSE,
  ...
) {
  features <- path |>
    find_features() |>
    filter_features(filter, ...)
  file <- fs::path(path, "test-__cucumber__.R")
  if (length(features) == 0) {
    abort("No feature files found")
  }
  with_file(file, {
    writeLines(
      test_cucumber_code(features),
      con = file
    )
    test_dir(
      path = path,
      filter = "^__cucumber__$",
      reporter = reporter,
      env = env,
      load_helpers = load_helpers,
      stop_on_failure = stop_on_failure,
      stop_on_warning = stop_on_warning
    )
  })
}

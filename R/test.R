#' Run Cucumber tests in a `testthat` context
#'
#' @description
#' It's purpose is to be able to run Cucumber tests alongside `testthat` tests.
#'
#' To do that, place a call to `run()` in one of the `test-*.R` files in your `tests/testthat` directory.
#'
#' @examples \dontrun{
#' #' tests/testthat/test-cucumber.R
#' cucumber::run()
#' }
#'
#' @param path Path to the directory containing the `.feature` files.
#'   If `run()` is placed in a `tests/testthat/test-*.R` file and you call `testthat::test_dir` or similar,
#'   it runs in the `tests/testthat` directory. The default value `"."` finds all feature
#'   files in the `tests/testthat` directory.
#'
#' @param filter If not NULL, only features with file names matching this regular expression
#'   will be executed. Matching is performed on the file name after it's stripped of ".feature".
#' @param ... Additional arguments passed to `grepl()`.
#' @return NULL, invisibly.
#'   To get result and a report, use `cucumber::test()`, or inspect the result of `testthat` function call.
#'
#' @importFrom purrr map walk
#' @export
#' @md
run <- function(
  path = ".",
  filter = NULL,
  ...
) {
  withr::defer(cleanup(), testthat::teardown_env())
  features <- path |>
    find_features() |>
    filter_features(filter, ...)

  if (length(features) == 0) {
    abort("No feature files found")
  }

  features |>
    map(readLines) |>
    map(validate_feature) |>
    walk(execute)

  invisible(NULL)
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
test_cucumber_code <- function(path, filter, ...) {
  sprintf(
    'cucumber::run(%s, %s)',
    shQuote(path),
    if (is.null(filter)) {
      "NULL"
    } else {
      shQuote(filter)
    }
  )
}

#' Run Cucumber tests
#'
#' @description
#' It runs  tests from specifications in `.feature` files found in the `path`.
#'
#' To run Cucumber tests alongside `testthat` tests, see `cucumber::run()`.
#'
#' @section Good Practices:
#'
#' - Use a separate directory for your acceptance tests, e.g. `tests/acceptance`.
#'
#'   It's not prohibited to use `tests/testthat` directory, but it's not recommended as those tests
#'   serve a different purpose and are better run separately, especially if acceptance tests take
#'   longer to run than unit tests.
#'
#'   If you want to run Cucumber tests alongside `testthat` tests, you can use `cucumber::run()` in one of the `test-*.R` files in your `tests/testthat` directory.
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
  file <- fs::path(path, "test-__cucumber__.R")
  with_file(file, {
    writeLines(
      test_cucumber_code(".", filter = filter, ...),
      con = file
    )
    result <- test_dir(
      path = path,
      filter = "^__cucumber__$",
      reporter = reporter,
      env = env,
      load_helpers = load_helpers,
      stop_on_failure = stop_on_failure,
      stop_on_warning = stop_on_warning
    )
  })
  invisible(result)
}

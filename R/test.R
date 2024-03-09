#' Run all Cucumber tests
#'
#' This command runs all Cucumber tests. It takes all .feature files
#' from the `features_dir` and runs them using the steps from the `steps_dir`.
#'
#' @param features_dir A character string of the directory containing the feature files.
#'   By default it checks "tests/testthat" directory. To setup a different, default directory
#'   use `option(cucumber_features_dir = "path/to/your/features")`.
#' @param steps_dir A character string of the directory containing the step files.
#'   By default it checks "tests/testthat/steps" directory. To setup a different, default directory
#'   use `option(cucumber_steps_dir = "path/to/your/steps")`.
#' @param steps_loader A function that loads the steps implementations. By default it sources all files
#'   from the \code{steps_dir} using the built-in mechanism. You can provide your own function to load
#'   the steps. The function should take one argument, which will be the \code{steps_dir}
#'   and return a list of steps.
#'
#' @export
#' @importFrom fs dir_ls
#' @importFrom purrr map walk
#' @importFrom checkmate assert_directory_exists assert_function assert_list
#' @importFrom withr defer
test <- function(
  features_dir = getOption("cucumber_features_dir", "tests/testthat"),
  steps_dir = getOption("cucumber_steps_dir", "tests/testthat/steps"),
  steps_loader = function(steps_dir) {
    steps_files <- dir_ls(steps_dir, glob = "*.R$", type = "file")
    walk(steps_files, source)
    get_steps()
  }
) {
  assert_directory_exists(features_dir)
  assert_directory_exists(steps_dir)
  assert_function(steps_loader, nargs = 1)
  defer({
    clear_steps()
    set_default_parameters()
  })
  steps <- steps_loader(steps_dir)
  assert_list(steps, types = "step")
  feature_files <- dir_ls(features_dir, glob = "*.feature$", type = "file")
  feature_files |>
    map(readLines) |>
    map(normalize_feature) |>
    walk(run, steps = steps, parameters = get_parameters())
}

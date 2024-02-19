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
#'
#' @export
#' @importFrom fs dir_ls
#' @importFrom purrr map walk
#' @importFrom checkmate assert_directory_exists
test <- function(
  features_dir = getOption("cucumber_features_dir", "tests/testthat"),
  steps_dir = getOption("cucumber_steps_dir", "tests/testthat/steps")
) {
  assert_directory_exists(features_dir)
  assert_directory_exists(steps_dir)
  feature_files <- dir_ls(features_dir, glob = "*.feature$", type = "file")
  steps_files <- dir_ls(steps_dir, glob = "*.R$", type = "file")
  walk(steps_files, source)
  feature_files |>
    map(readLines) |>
    map(normalize_feature) |>
    walk(run, steps = get_steps(), parameters = get_parameters())
}

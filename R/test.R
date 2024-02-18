#' Test
#'
#' @param features_dir A character string of the directory containing the feature files.
#' @param steps_dir A character string of the directory containing the step files.
#'
#' @export
#' @importFrom fs dir_ls
#' @importFrom purrr map walk
#' @importFrom checkmate assert_directory_exists
test <- function(
  features_dir = "tests/testthat",
  steps_dir = "tests/testthat/steps"
) {
  assert_directory_exists(features_dir)
  assert_directory_exists(steps_dir)
  feature_files <- dir_ls(features_dir, glob = "*.feature$", type = "file")
  steps_files <- dir_ls(steps_dir, glob = "*.R$", type = "file")
  walk(steps_files, source)
  feature_files |>
    map(readLines) |>
    walk(run, steps = get_steps(), parameters = get_parameters())
}

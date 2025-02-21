#' @importFrom fs dir_ls
#' @importFrom purrr map walk
.default_steps_loader <- function(steps_dir) {
  steps_files <- dir_ls(steps_dir, glob = "*.R$", type = "file")
  walk(steps_files, source)
}

#' Run all Cucumber tests
#'
#' This command runs all Cucumber tests. It takes all .feature files
#' from the \code{features_dir} and runs them using the steps from the \code{steps_dir}.
#'
#' @param features_dir A character string of the directory containing the feature files.
#' @param steps_dir A character string of the directory containing the step files.
#' @param steps_loader A function that loads the steps implementations. By default it sources all files
#'   from the \code{steps_dir} using the built-in mechanism. You can provide your own function to load
#'   the steps. The function should take one argument, which will be the \code{steps_dir}.
#'
#'   **For packages**: set to NULL to use default support-code load mechanism and place your steps
#'   definitions in `setup` or `helper` files. Read more about those files in
#'   [testthat documentation](https://testthat.r-lib.org/articles/special-files.html).
#' @param test_interactive A logical value indicating whether to ask which feature files to run.
#' @return None, function called for side effects.
#'
#' @examples
#' \dontrun{
#' #' testthat/acceptance/test-cucumber.R
#' cucumber::test(".", ".", steps_loader = NULL)
#' # Steps are stored in `testthat/acceptance/setup-steps.R` file.
#' }
#'
#' @md
#' @export
#' @importFrom fs dir_ls
#' @importFrom purrr map walk
#' @importFrom checkmate assert_directory_exists assert_function assert_list test_function
#' @importFrom withr defer
#' @importFrom utils menu
test <- function(
  features_dir,
  steps_dir,
  steps_loader = .default_steps_loader,
  test_interactive = getOption("cucumber.interactive", default = FALSE)
) {
  assert_directory_exists(features_dir)
  assert_directory_exists(steps_dir)
  assert_function(steps_loader, nargs = 1, null.ok = TRUE)
  defer({
    clear_steps()
    clear_hooks()
    set_default_parameters()
  })
  if (test_function(steps_loader)) {
    steps_loader(steps_dir)
  }
  feature_files <- dir_ls(features_dir, glob = "*.feature$", type = "file")
  if (test_interactive) { # nocov start
    selection <- menu(
      choices = c("All", feature_files),
      title = "Select feature files to run"
    )
    if (selection == 1) {
      feature_files <- feature_files
    } else {
      feature_files <- feature_files[selection - 1]
    }
  } # nocov end
  feature_files |>
    map(readLines) |>
    map(validate_feature) |>
    walk(run, parameters = get_parameters())
}

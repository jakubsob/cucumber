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
#' @param path Path to the directory containing the `.feature` files. Its subdirectories are searched too.
#'   If `run()` is placed in a `tests/testthat/test-*.R` file and you call `testthat::test_dir` or similar,
#'   it runs in the `tests/testthat` directory. The default value `"."` finds all feature
#'   files in the `tests/testthat` directory.
#'
#' @param filter If not NULL, only features with file names matching this regular expression
#'   will be executed. Matching is performed on the file name after it's stripped of ".feature".
#' @param tags If not NULL, filter scenarios by tag expression string
#'   (e.g., `"@smoke and not @slow"`, `"@gui or @database"`).
#'   Tag expressions support `and`, `or`, `not` operators and parentheses for grouping,
#'   like the official [cucumber/tag-expressions](https://github.com/cucumber/tag-expressions).
#'   Tags are written with their `@`. Escape a parenthesis in a tag with a backslash, e.g. `"@wip\\(x\\)"`.
#' @param name If not NULL, only scenarios with names matching any of these regular expressions
#'   will be executed. For a Scenario Outline, the name is matched after its `<placeholders>` are replaced.
#' @param features If not NULL, only these feature files will be executed. Paths are relative to `path`.
#'   Add `:line` to run only the scenario at that line, e.g. `"addition.feature:12"`, or several
#'   lines, e.g. `"addition.feature:12:20"`. The line of a Scenario Outline runs all of its examples,
#'   the line of an example row runs only that example.
#' @param strict If `TRUE`, pending and undefined steps fail the scenario.
#'   If `FALSE`, they skip it.
#' @param dry_run If `TRUE`, steps are matched to step definitions, but neither
#'   step definitions nor hooks are run. Use it to find undefined and ambiguous steps.
#'   They are reported, but don't fail a dry run: a scenario with one is skipped.
#' @param fail_fast If `TRUE`, the scenarios after the first failed scenario are skipped:
#'   their hooks and steps don't run. With `strict = TRUE`, a scenario with a pending or
#'   undefined step counts as failed.
#' @param reporter Optional reporter instance (testthat::Reporter or cucumber::CucumberReporter).
#'   If NULL, will use reporter from package options if available.
#' @param ... Additional arguments passed to `grepl()`.
#' @return NULL, invisibly.
#'   To get result and a report, use `cucumber::test()`, or inspect the result of `testthat` function call.
#'
#' @importFrom rlang abort
#' @export
#' @md
run <- function(
  path = ".",
  filter = NULL,
  tags = NULL,
  reporter = get_reporter(),
  strict = TRUE,
  dry_run = FALSE,
  name = NULL,
  features = NULL,
  fail_fast = FALSE,
  ...
) {
  withr::defer(cleanup(), testthat::teardown_env())

  lines <- feature_lines(features, path)
  features <- (if (is.null(features)) find_features(path) else names(lines)) |>
    filter_features(filter, ...)

  if (length(features) == 0) {
    abort(
      "No feature files found.",
      body = c(
        i = "Add `.feature` files describing your scenarios."
      ),
      trace = empty_trace()
    )
  }

  # A dry run runs no hooks
  hooks <- if (dry_run) .hooks() else get_hooks()
  on.exit({
    after_error <- run_hooks(get_hooks_to_run(hooks, "after_all"), stop_on_error = FALSE)
    if (!is.null(after_error)) stop(after_error)
  })
  before_error <- run_hooks(get_hooks_to_run(hooks, "before_all"))
  if (!is.null(before_error)) {
    stop(before_error)
  }

  failed <- FALSE
  for (feature_path in features) {
    failed <- execute(
      read_feature(feature_path),
      feature_file = feature_path,
      tags = tags,
      name = name,
      lines = lines[[feature_path]],
      reporter = reporter,
      strict = strict,
      dry_run = dry_run,
      fail_fast = fail_fast,
      failed = failed
    )
  }

  invisible(NULL)
}

#' @importFrom fs dir_ls
find_features <- function(path) {
  dir_ls(path, glob = "*.feature$", type = "file", recurse = TRUE)
}

#' Split `file:line:line` locations into a list of lines named by file. A file
#' without lines runs all its scenarios, unless another location of it has lines.
#' @keywords internal
#' @noRd
#' @importFrom fs file_exists
feature_lines <- function(features, path) {
  if (is.null(features)) {
    return(list())
  }
  files <- fs::path(path, sub("(:[0-9]+)*$", "", features))
  missing <- unique(files[!file_exists(files)])
  if (length(missing) > 0) {
    abort(
      "Feature files not found.",
      body = rlang::set_names(missing, "x"),
      trace = empty_trace()
    )
  }
  lines <- regmatches(features, regexpr("(:[0-9]+)*$", features)) |>
    strsplit(":") |>
    lapply(\(x) as.integer(x[x != ""]))
  lapply(split(lines, files), \(x) unique(unlist(x, use.names = FALSE)))
}

read_feature <- function(path) {
  readLines(path, warn = FALSE, encoding = "UTF-8")
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

#' @importFrom rlang call2 list2
#' @importFrom purrr compact
test_cucumber_code <- function(path, ...) {
  # Arguments left at their default are dropped, so error messages show only what was set
  call2("run", .ns = "cucumber", path, !!!compact(list2(...)), reporter = quote(getOption(".cucumber_reporter"))) |>
    deparse1()
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
#' @param path Path to the directory containing the `.feature` files. Its subdirectories are
#'   searched too. Defaults to the `cucumber.path` option, or `"tests/acceptance"` if it's not set.
#' @param filter If not NULL, only features with file names matching this regular expression
#'   will be executed. Matching is performed on the file name after it's stripped of ".feature".
#' @param tags If not NULL, filter scenarios by tag expression string
#'   (e.g., `"@smoke and not @slow"`, `"@gui or @database"`).
#'   Tag expressions support `and`, `or`, `not` operators and parentheses for grouping,
#'   like the official [cucumber/tag-expressions](https://github.com/cucumber/tag-expressions).
#'   Tags are written with their `@`. Escape a parenthesis in a tag with a backslash, e.g. `"@wip\\(x\\)"`.
#' @param name If not NULL, only scenarios with names matching any of these regular expressions
#'   will be executed. For a Scenario Outline, the name is matched after its `<placeholders>` are replaced.
#' @param features If not NULL, only these feature files will be executed. Paths are relative to `path`.
#'   Add `:line` to run only the scenario at that line, e.g. `"addition.feature:12"`, or several
#'   lines, e.g. `"addition.feature:12:20"`. The line of a Scenario Outline runs all of its examples,
#'   the line of an example row runs only that example.
#' @param strict If `TRUE`, pending and undefined steps fail the scenario.
#'   If `FALSE`, they skip it.
#' @param dry_run If `TRUE`, steps are matched to step definitions, but neither
#'   step definitions nor hooks are run. Use it to find undefined and ambiguous steps.
#'   They are reported, but don't fail a dry run: a scenario with one is skipped.
#' @param fail_fast If `TRUE`, the scenarios after the first failed scenario are skipped:
#'   their hooks and steps don't run. With `strict = TRUE`, a scenario with a pending or
#'   undefined step counts as failed.
#'
#' @examples
#' \dontrun{
#' cucumber::test("tests/acceptance")
#' cucumber::test("tests/acceptance", filter = "addition|multiplication")
#'
#' # Scenarios by name or by line
#' cucumber::test("tests/acceptance", name = "^Adding")
#' cucumber::test("tests/acceptance", features = "addition.feature:12")
#'
#' # Tag expressions
#' cucumber::test("tests/acceptance", tags = "@smoke")
#' cucumber::test("tests/acceptance", tags = "@smoke and @fast")
#' cucumber::test("tests/acceptance", tags = "@wip and not @slow")
#' cucumber::test("tests/acceptance", tags = "(@smoke or @ui) and (not @slow)")
#'
#' # Find undefined steps without running anything
#' cucumber::test("tests/acceptance", dry_run = TRUE)
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
  path = getOption("cucumber.path", "tests/acceptance"),
  filter = NULL,
  tags = NULL,
  reporter = get_reporter(),
  env = NULL,
  load_helpers = TRUE,
  stop_on_failure = TRUE,
  stop_on_warning = FALSE,
  strict = TRUE,
  dry_run = FALSE,
  name = NULL,
  features = NULL,
  fail_fast = FALSE,
  ...
) {
  if (!is.null(reporter)) {
    withr::local_options(.cucumber_reporter = reporter)
  }

  file <- fs::path(path, "test-__cucumber__.R")
  with_file(file, {
    writeLines(
      test_cucumber_code(
        ".",
        filter = filter,
        tags = tags,
        strict = if (!strict) FALSE,
        dry_run = if (dry_run) TRUE,
        name = name,
        features = features,
        fail_fast = if (fail_fast) TRUE,
        ...
      ),
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

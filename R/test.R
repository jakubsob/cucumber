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
#' @param features If not NULL, only these feature files will be executed. Relative paths are relative to `path`.
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
#' @param reporter A [CucumberReporter], or `NULL` to report nothing.
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
  check_reporter(reporter)
  error <- NULL
  # An error of a reporter or of cucumber itself stops the run, see abort_run()
  broken <- FALSE
  withRestarts(
    tryCatch(
      withCallingHandlers(
        {
          cucumber_event(reporter, "start_run")
          run_features(path, filter, tags, reporter, strict, dry_run, name, features, fail_fast, ...)
        },
        # Warnings outside scenarios, like in a before all hook. testthat keeps a
        # scenario's warnings, so they don't get here: execute_single_pickle() reports them.
        warning = \(w) cucumber_event(reporter, "add_warning", w)
      ),
      error = function(e) error <<- e
    ),
    cucumber_abort_run = function(e) {
      error <<- e
      broken <<- TRUE
    }
  )
  # The reporter gets the error that stopped the run, like a failing before all
  # hook, unless it's the reporter that failed
  if (!inherits(error, "cucumber_reporter_error")) {
    end_error <- tryCatch(
      cucumber_event(reporter, "end_run", error),
      cucumber_reporter_error = identity
    )
    if (inherits(end_error, "cucumber_reporter_error")) {
      error <- end_error
      broken <- TRUE
    }
  }
  if (broken) fail_test(error)
  if (!is.null(error)) stop(error)
  invisible(NULL)
}

#' Stop the run with an error of a reporter or of cucumber itself, from wherever
#' it's raised: testthat would report it as the failure of a scenario and run
#' the next one.
#' @keywords internal
#' @noRd
abort_run <- function(error) {
  if (has_restart("cucumber_abort_run")) {
    invokeRestart("cucumber_abort_run", error)
  }
  stop(error)
}

has_restart <- function(name) {
  !is.null(findRestart(name))
}

#' Stop `test()` with an error of a reporter or of cucumber itself: testthat
#' would report it as the failure of the test file. Outside of `test()`, like
#' with `run()` in a testthat file, it's an error of the test file.
#' @keywords internal
#' @noRd
fail_test <- function(error) {
  if (has_restart("cucumber_fail_test")) {
    invokeRestart("cucumber_fail_test", error)
  }
  stop(error)
}

#' Run the feature files, see `run()`
#' @keywords internal
#' @noRd
run_features <- function(path, filter, tags, reporter, strict, dry_run, name, features, fail_fast, ...) {
  withr::defer(cleanup(), testthat::teardown_env())
  check_grepl_args(...)

  lines <- feature_lines(features, path)
  features <- select_features(path, filter, lines, ...)

  # A run nested in another one, like in a step that tests cucumber, has ids of
  # its own, and the outer run's ids continue after it
  outer_id <- ids$next_id
  reset_ids()
  on.exit(ids$next_id <- outer_id, add = TRUE)
  emit(reporter, "meta", meta_message())
  sources <- parse_features(features, reporter)
  glue <- emit_glue(reporter, get_steps(), get_hooks(), get_parameters())
  # A dry run runs no hooks
  hooks <- if (dry_run) .hooks() else glue$hooks

  test_run_started <- list(id = new_id(), timestamp = timestamp())
  emit(reporter, "testRunStarted", test_run_started)
  failed <- FALSE
  before_error <- NULL
  on.exit({
    after_error <- run_test_run_hooks(get_hooks_to_run(hooks, "after_all"), reporter, test_run_started$id)
    emit(reporter, "testRunFinished", list(
      testRunStartedId = test_run_started$id,
      timestamp = timestamp(),
      success = !failed && is.null(before_error) && is.null(after_error)
    ))
    if (!is.null(after_error)) stop(after_error)
  }, add = TRUE, after = FALSE)
  # Like in cucumber-js, every before all hook runs, but no scenario runs if one failed
  before_error <- run_test_run_hooks(get_hooks_to_run(hooks, "before_all"), reporter, test_run_started$id)
  if (!is.null(before_error)) {
    stop(before_error)
  }

  pickles <- map(set_names(features), \(path) {
    prepare_pickles(
      sources[[path]]$pickles,
      glue$steps,
      get_parameters(),
      hooks,
      tags = tags,
      name = name,
      lines = lines[[path]],
      reporter = reporter,
      test_run_started_id = test_run_started$id
    )
  })
  for (path in features) {
    failed <- execute_feature(
      sources[[path]]$document,
      pickles[[path]],
      hooks,
      reporter = reporter,
      strict = strict,
      dry_run = dry_run,
      fail_fast = fail_fast,
      failed = failed
    )
  }

  invisible(NULL)
}

#' Run before all or after all hooks, each reported as a test run hook. All of
#' them run, and the first error is returned.
#' @keywords internal
#' @noRd
run_test_run_hooks <- function(hooks, reporter, test_run_started_id) {
  first_error <- NULL
  for (hook in hooks) {
    started <- list(id = new_id(), testRunStartedId = test_run_started_id, hookId = hook$id, timestamp = timestamp())
    emit(reporter, "testRunHookStarted", started)
    result <- run_hook_step(hook)
    emit(reporter, "testRunHookFinished", list(
      testRunHookStartedId = started$id,
      result = test_step_result(result),
      timestamp = timestamp()
    ))
    first_error <- first_error %||% result$error
  }
  first_error
}

#' The feature files selected by `features` and `filter`, see `test()`
#' @param lines Lines of the `features`, from `feature_lines()`
#' @keywords internal
#' @noRd
select_features <- function(path, filter, lines, ...) {
  features <- (if (length(lines) == 0) find_features(path) else names(lines)) |>
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
  features
}

#' @importFrom fs dir_ls is_file
find_features <- function(path) {
  # A symbolic link to a feature file is run too
  features <- dir_ls(path, glob = "*.feature$", type = c("file", "symlink"), recurse = TRUE)
  features[is_file(features)]
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
  files <- sub("(:[0-9]+)*$", "", features)
  files <- ifelse(fs::is_absolute_path(files), files, fs::path(path, files))
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
  # A factor keeps the files in the order they're given
  lapply(split(lines, factor(files, unique(files))), \(x) unique(unlist(x, use.names = FALSE)))
}

read_feature <- function(path) {
  readLines(path, warn = FALSE, encoding = "UTF-8")
}

#' Parse feature files and compile their pickles, reporting the source,
#' document and pickles of each file
#'
#' Like cucumber-js, nothing runs if any feature file can't be parsed, and the
#' errors of every file are reported.
#'
#' @return A list named by path, with the `document` and the `pickles` of each file
#' @keywords internal
#' @noRd
#' @importFrom rlang try_fetch abort
#' @importFrom purrr map set_names walk
parse_features <- function(paths, reporter = NULL) {
  documents <- map(paths, \(path) {
    emit(reporter, "source", source_message(path))
    document <- try_fetch(
      parse_gherkin(read_feature(path), uri = path),
      cucumber_parse_error = identity
    )
    if (inherits(document, "cucumber_parse_error")) {
      walk(document$errors, \(error) emit(reporter, "parseError", parse_error_message(path, error)))
      return(document)
    }
    emit(reporter, "gherkinDocument", document)
    pickles <- create_pickles(document, feature_file = path)
    walk(pickles, \(pickle) emit(reporter, "pickle", pickle$message))
    list(document = document, pickles = pickles)
  })
  errors <- Filter(\(document) inherits(document, "cucumber_parse_error"), documents)
  if (length(errors) > 0) {
    messages <- unlist(map(errors, \(error) sprintf('Parse error in "%s" %s', error$uri, error$errors)))
    abort(
      "Can't parse feature files",
      body = set_names(messages, rep("x", length(messages))),
      class = "cucumber_parse_error",
      trace = empty_trace(),
      call = NULL
    )
  }
  set_names(documents, paths)
}

#' @importFrom fs path_ext_remove path_file
context_name <- function(feature) {
  feature |>
    path_file() |>
    path_ext_remove()
}

#' `...` of test() and run() is passed to grepl(), so a misspelled argument
#' would be ignored without a filter
#' @keywords internal
#' @noRd
check_grepl_args <- function(...) {
  allowed <- setdiff(names(formals(grepl)), c("pattern", "x"))
  unknown <- setdiff(names(list(...)), c(allowed, ""))
  if (length(unknown) > 0) {
    abort(
      paste0("Unknown argument", if (length(unknown) > 1) "s", ": ", paste0("`", unknown, "`", collapse = ", "), "."),
      body = c(i = paste0("Arguments of `grepl()` for `filter` can be passed in `...`: ", paste0("`", allowed, "`", collapse = ", "), ".")),
      trace = empty_trace()
    )
  }
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
#' @param reporter A [CucumberReporter], or `NULL` to report nothing. Defaults to
#'   [CucumberProgressReporter].
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
#' @param features If not NULL, only these feature files will be executed. Relative paths are relative to `path`.
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
  check_reporter(reporter)
  withr::local_options(.cucumber_reporter = reporter)

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
    result <- withRestarts(
      test_dir(
        path = path,
        filter = "^__cucumber__$",
        # Cucumber's reporter gets the run's events from run(), testthat reports nothing
        reporter = testthat::SilentReporter$new(),
        env = env,
        load_helpers = load_helpers,
        stop_on_failure = stop_on_failure,
        stop_on_warning = stop_on_warning
      ),
      cucumber_fail_test = function(error) stop(error)
    )
  })
  invisible(result)
}

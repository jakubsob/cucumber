#' Run Cucumber tests in a `testthat` context
#'
#' @description
#' Call `run()` in a `tests/testthat/test-*.R` file to run the feature files
#' alongside the package's `testthat` tests.
#'
#' @examples \dontrun{
#' #' tests/testthat/test-cucumber.R
#' cucumber::run()
#' }
#'
#' @inheritParams test
#' @param path Path to the directory containing the `.feature` files. Its subdirectories are searched too.
#'   If `run()` is placed in a `tests/testthat/test-*.R` file and you call `testthat::test_dir` or similar,
#'   it runs in the `tests/testthat` directory. The default value `"."` finds all feature
#'   files in the `tests/testthat` directory.
#' @param reporter A [CucumberReporter], or `NULL`, the default, to leave the output to
#'   testthat's reporter, which reports each scenario as a test.
#' @param ... Additional arguments passed to `grepl()`.
#' @return NULL, invisibly.
#'
#' @details
#' Each `run()` is a run of its own: its [before_all()] and [after_all()] hooks run
#' once for each `run()`, so twice if two test files call `run()`. Step definitions,
#' hooks and parameter types are kept until testthat's run ends, as testthat runs the
#' `setup-*.R` files that define them once for all test files. Outside of a testthat run,
#' like when `run()` is called in the console, they're kept until `run()` returns.
#'
#' `run()` in a parallel testthat run, with `Config/testthat/parallel: true`, is an error:
#' testthat would delete the snapshot files of its feature files as unused.
#'
#' Skip scenarios in a [before_all()] or [before()] hook, not with `skip()` before `run()` in its
#' test file: testthat deletes the snapshot files of feature files that a run of every test file
#' didn't run.
#'   To get result and a report, use `cucumber::test()`, or inspect the result of `testthat` function call.
#'
#' @eval features_rd(features = "r-running_alongside_testthat.feature")
#'
#' @importFrom rlang abort
#' @export
#' @md
run <- function(
  path = ".",
  filter = NULL,
  tags = NULL,
  reporter = NULL,
  strict = TRUE,
  dry_run = FALSE,
  name = NULL,
  features = NULL,
  fail_fast = FALSE,
  retry = 0,
  order = "defined",
  ...
) {
  # Each process of a parallel run would save the snapshots of the feature files
  # in its own snapshotter, and the main process would delete them as unused
  if (identical(Sys.getenv("TESTTHAT_IS_PARALLEL"), "true")) {
    abort(
      "`run()` isn't supported in a parallel testthat run.",
      body = c(i = "Set `Config/testthat/parallel: false` in DESCRIPTION, or run the feature files with `cucumber::test()`."),
      call = NULL,
      trace = empty_trace()
    )
  }
  # Step definitions and hooks are cleared at the end of testthat's run, as the
  # setup files that registered them run once for all test files
  cleanup_env <- tryCatch(testthat::teardown_env(), error = \(e) NULL) %||% environment()
  run_cucumber(path, filter, tags, reporter, strict, dry_run, name, features, fail_fast, retry, order, ..., cleanup_env = cleanup_env)
}

#' Run the feature files and report the run, see `run()`
#' @param cleanup_env The environment whose end clears step definitions, hooks
#'   and parameter types
#' @param start_file A function called with each feature file before its
#'   scenarios run, or `NULL`
#' @keywords internal
#' @noRd
run_cucumber <- function(path, filter, tags, reporter, strict, dry_run, name, features, fail_fast, retry, order, ..., cleanup_env, start_file = NULL) {
  check_reporter(reporter)
  retry <- checkmate::assert_count(retry, coerce = TRUE)
  order <- resolve_order(order)
  error <- NULL
  # An error of a reporter or of cucumber itself stops the run, see abort_run()
  broken <- FALSE
  withRestarts(
    tryCatch(
      withCallingHandlers(
        {
          cucumber_event(reporter, "start_run")
          run_features(path, filter, tags, reporter, strict, dry_run, name, features, fail_fast, retry, order, ..., cleanup_env = cleanup_env, start_file = start_file)
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
    # A restart of its own, or the error would stop the run this one is nested in
    end_error <- withRestarts(
      cucumber_event(reporter, "end_run", error),
      cucumber_abort_run = identity
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
run_features <- function(path, filter, tags, reporter, strict, dry_run, name, features, fail_fast, retry, order, ..., cleanup_env, start_file = NULL) {
  withr::defer(cleanup(), cleanup_env)
  # Before anything can stop the run, or testthat would delete the snapshot
  # files of the features as unused
  complete <- complete_run(filter, tags, name, features, dry_run)
  snapshots <- run_snapshots(path, find_features(path), complete)
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
  # Every before all hook runs, but no scenario runs if one failed. One that
  # skipped skips every scenario, like skip() at the top of a test file.
  before_error <- run_test_run_hooks(get_hooks_to_run(hooks, "before_all"), reporter, test_run_started$id, can_skip = TRUE)
  skip <- if (inherits(before_error, "skip")) before_error
  if (!is.null(skip)) before_error <- NULL
  if (!is.null(before_error)) {
    stop(before_error)
  }

  # The scenarios of all features are put in order together
  pickles <- unlist(
    map(unname(features), \(path) filter_pickles(sources[[path]]$pickles, tags, name, lines[[path]])),
    recursive = FALSE
  )
  pickles <- prepare_pickles(
    order_pickles(pickles, order),
    glue$steps,
    get_parameters(),
    hooks,
    reporter = reporter,
    test_run_started_id = test_run_started$id
  )
  # Consecutive scenarios of a feature run in its testthat context
  files <- rle(map_chr(pickles, "feature_file"))
  for (run in split(pickles, rep(seq_along(files$lengths), files$lengths))) {
    if (!is.null(start_file)) start_file(run[[1]]$feature_file)
    failed <- execute_feature(
      sources[[run[[1]]$feature_file]]$document,
      run,
      hooks,
      reporter = reporter,
      strict = strict,
      dry_run = dry_run,
      fail_fast = fail_fast,
      retry = retry,
      failed = failed,
      skip = skip,
      snapshots = snapshots$feature(run[[1]]$feature_file, map_chr(sources[[run[[1]]$feature_file]]$pickles, "test_name"))
    )
  }
  # A run that skipped scenarios after a failed one, or all of them in a before
  # all hook, didn't run every scenario
  if (!(fail_fast && failed) && is.null(skip)) snapshots$finish()

  invisible(NULL)
}

#' Check `order`, see `test()`. A random order without a seed gets one, shown
#' so the same order can be run again.
#' @return The order, with a seed if it's random
#' @keywords internal
#' @noRd
resolve_order <- function(order) {
  checkmate::assert_string(order)
  if (!grepl("^(defined|reverse|random(:[0-9]+)?)$", order)) {
    abort(
      paste0("Unknown order \"", order, "\"."),
      body = c(i = "Use \"defined\", \"reverse\", \"random\" or \"random:<seed>\", like \"random:1234\"."),
      call = NULL,
      trace = empty_trace()
    )
  }
  if (order == "random") {
    # Without changing the session's random numbers
    order <- paste0("random:", withr::with_preserve_seed(sample.int(99999L, 1L)))
    rlang::inform(paste0("Running scenarios in random order. Use `order = \"", order, "\"` to run them in this order again."))
  }
  order
}

#' Pickles in the order to run them, see `resolve_order()`
#' @keywords internal
#' @noRd
order_pickles <- function(pickles, order) {
  switch(
    sub(":.*", "", order),
    defined = pickles,
    reverse = rev(pickles),
    random = withr::with_seed(as.integer(sub("^random:", "", order)), pickles[sample.int(length(pickles))])
  )
}

#' Run before all or after all hooks, each reported as a test run hook. All of
#' them run, and the first error is returned, or with `can_skip` the first skip
#' if none failed.
#' @keywords internal
#' @noRd
run_test_run_hooks <- function(hooks, reporter, test_run_started_id, can_skip = FALSE) {
  first_error <- NULL
  first_skip <- NULL
  for (hook in hooks) {
    started <- list(id = new_id(), testRunStartedId = test_run_started_id, hookId = hook$id, timestamp = timestamp())
    emit(reporter, "testRunHookStarted", started)
    context <- new_context(\(attachment) emit(reporter, "attachment", c(list(testRunHookStartedId = started$id), attachment)))
    result <- withr::with_options(list(testthat.snapshotter = test_run_hook_snapshotter()), run_hook_step(hook, context, can_skip = can_skip))
    emit(reporter, "testRunHookFinished", list(
      testRunHookStartedId = started$id,
      result = test_step_result(result),
      timestamp = timestamp()
    ))
    if (inherits(result$error, "skip")) first_skip <- first_skip %||% result$error else first_error <- first_error %||% result$error
  }
  first_error %||% first_skip
}

#' A snapshotter for before all and after all hooks: a snapshot is of a
#' scenario, so taking one there is an error
#' @keywords internal
#' @noRd
test_run_hook_snapshotter <- function() {
  error <- \(fn) \(...) abort(paste0("`", fn, "` can only be called in a step, or in a `before()`, `after()`, `before_step()` or `after_step()` hook."), call = NULL)
  list(
    is_active = \() TRUE,
    take_snapshot = error("testthat::expect_snapshot()"),
    take_file_snapshot = error("testthat::expect_snapshot_file()"),
    announce_file_snapshot = error("testthat::announce_snapshot_file()")
  )
}

#' The feature files selected by `features` and `filter`, see `test()`
#' @param lines Lines of the `features`, from `feature_lines()`
#' @keywords internal
#' @noRd
select_features <- function(path, filter, lines, ...) {
  # No locations, like the rerun file of a run whose scenarios passed, select nothing
  if (!is.null(lines) && length(lines) == 0) {
    return(character())
  }
  features <- (if (is.null(lines)) find_features(path) else names(lines)) |>
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
  features <- dir_ls(path, regexp = feature_file_pattern(), type = c("file", "symlink"), recurse = TRUE)
  # Snapshot files, like `_snaps/basket.feature.md`, aren't feature files
  features[is_file(features) & !grepl("(^|/)_snaps/", fs::path_rel(features, path))]
}

#' Split `file:line:line` locations into a list of lines named by file. A file
#' without lines runs all its scenarios, unless another location of it has lines.
#' `NULL` without locations.
#' @keywords internal
#' @noRd
#' @importFrom fs file_exists
feature_lines <- function(features, path) {
  if (is.null(features)) {
    return(NULL)
  }
  if (length(features) == 0) {
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
#' Nothing runs if any feature file can't be parsed, and the errors of every
#' file are reported.
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

#' @importFrom fs path_file
context_name <- function(feature) {
  sub(feature_file_pattern(), "", path_file(feature))
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

#' Restore the step definitions, hooks and parameter types when `frame` ends
#' @keywords internal
#' @noRd
local_registry <- function(frame = parent.frame()) {
  names <- c(getOption(".cucumber_steps_option"), getOption(".cucumber_hooks_option"), getOption(".cucumber_parameters_option"))
  registry <- lapply(rlang::set_names(names), getOption)
  withr::defer(options(registry), frame)
}

#' Run Cucumber tests
#'
#' @description
#' It runs  tests from specifications in `.feature` files found in the `path`.
#'
#' To run Cucumber tests alongside `testthat` tests, see `cucumber::run()`.
#'
#' @section testthat's teardown environment:
#' `testthat::teardown_env()` isn't available in the `setup-*.R` files `test()` runs: use a
#' `teardown-*.R` file or an [after_all()] hook to clean up after the run. When `test()` is
#' called in a testthat test file, `teardown_env()` is the end of that testthat run.
#'
#' @section test() in a testthat file:
#' `test()` keeps the step definitions, hooks and parameter types registered before it, like by
#' the setup files of the testthat run, for the test files after it. A setup file of `path` that
#' testthat runs too, like with `test(".")` in a file of `tests/testthat`, defines its step
#' definitions again rather than twice. `test(".")` in a file of `tests/testthat` tells testthat
#' which snapshot files its feature files use, and is an error in a parallel testthat run.
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
#' @param filter If not NULL, run only the feature files whose name matches this regular expression.
#' @param tags If not NULL, run only the scenarios that match this tag expression, e.g. `"@smoke and not @slow"`.
#' @param name If not NULL, run only the scenarios whose name matches any of these regular expressions.
#' @param features If not NULL, run only these feature files, relative to `path`.
#'   Add `:line` to run only the scenario at that line, e.g. `"addition.feature:12"`.
#'   An empty vector runs no scenario.
#' @param strict If `FALSE`, pending and undefined steps don't fail the run.
#' @param dry_run If `TRUE`, match steps to step definitions without running steps or hooks.
#' @param fail_fast If `TRUE`, skip the scenarios after the first failed scenario.
#' @param retry How many times to run a failed scenario again, until it passes. Only
#'   failed scenarios are retried, not pending, undefined or ambiguous ones.
#' @param order The order to run scenarios in: `"defined"`, the order of the feature files
#'   and of the scenarios in them, `"reverse"`, or `"random"`. `"random:<seed>"`, like
#'   `"random:1234"`, runs them in the random order of that seed. Without a seed, the seed
#'   is chosen and shown, to run them in the same order again.
#' @param env Environment in which to run the tests, e.g. with step definitions and
#'   code sourced into it, for a project that isn't a package.
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
#' @eval features_rd(features = c(
#'   "r-running_tests.feature",
#'   "r-support_code.feature",
#'   "r-projects_that_arent_packages.feature",
#'   "paths.feature",
#'   "target_specific_scenarios_by_tag.feature",
#'   "target_specific_scenarios_by_name.feature",
#'   "target_specific_scenarios_by_line.feature",
#'   "strict_mode.feature",
#'   "dryrun_mode.feature",
#'   "fail_fast.feature",
#'   "retry.feature",
#'   "order.feature",
#'   "markdown_with_gherkin.feature"
#' ))
#'
#' @importFrom withr defer
#' @importFrom fs path
#' @importFrom checkmate test_character
#' @importFrom rlang abort
#' @export
#' @md
test <- function(
  path = getOption("cucumber.path", "tests/acceptance"),
  filter = NULL,
  tags = NULL,
  reporter = CucumberProgressReporter$new(),
  env = NULL,
  load_helpers = TRUE,
  stop_on_failure = TRUE,
  stop_on_warning = FALSE,
  strict = TRUE,
  dry_run = FALSE,
  name = NULL,
  features = NULL,
  fail_fast = FALSE,
  retry = 0,
  order = "defined",
  ...
) {
  check_reporter(reporter)
  checkmate::assert_count(retry)
  order <- resolve_order(order)
  # Before the working directory is `path`, like `features = readLines("rerun.txt")`
  list(filter, tags, env, name, features, ...)

  # What testthat::test_dir() does before it runs test files. It attaches
  # testthat, so steps can use its expectations without `testthat::`.
  if (!"package:testthat" %in% search()) attachNamespace("testthat")
  # Like testthat::test_local(), so snapshots are checked, but not in a testthat
  # run or in R CMD check, where skip_on_cran() still skips
  if (!testthat::is_testing() && Sys.getenv("_R_CHECK_PACKAGE_NAME_") == "" && Sys.getenv("NOT_CRAN") == "") {
    withr::local_envvar(NOT_CRAN = "true")
  }
  # Snapshots aren't of a testthat file that calls test(). testthat's snapshotter
  # of `path`, like with test(".") in a file of tests/testthat, is kept to be told
  # of the snapshot files of the features, or it deletes them at the end of its run.
  # Its directory is relative, so it's compared before the working directory changes.
  snapshotter <- getOption("testthat.snapshotter")
  if (!is.null(snapshotter) && fs::path_abs(snapshotter$snap_dir) != fs::path_abs(fs::path(path, "_snaps"))) snapshotter <- NULL
  # In a parallel run, the process that deletes the unused snapshot files can't be told
  if (!is.null(snapshotter) && identical(Sys.getenv("TESTTHAT_IS_PARALLEL"), "true")) {
    abort(
      "`test()` of the directory of a parallel testthat run isn't supported.",
      body = c(i = "Set `Config/testthat/parallel: false` in DESCRIPTION, or keep the feature files in another directory, like `test(\"../acceptance\")`."),
      call = NULL,
      trace = empty_trace()
    )
  }
  testthat::local_test_directory(path)
  # Like testthat::test_local(), testthat::testing_package() is the package of
  # `path`, the default package of testthat::local_mocked_bindings()
  package <- tryCatch(pkgload::pkg_name("."), error = \(e) NULL)
  if (!is.null(package)) withr::local_envvar(TESTTHAT_PKG = package)
  env <- env %||% testthat::test_env()
  withr::local_options(topLevelEnvironment = rlang::env_parent(env))
  withr::local_options(testthat.snapshotter = snapshotter)
  # Before the setup files, so what they defined is cleared even if one fails,
  # and what was defined before, like by the setup files of a testthat run that
  # calls test(), is restored
  local_registry()
  if (load_helpers) testthat::source_test_helpers(".", env)
  testthat::source_test_setup(".", env)
  withr::defer(testthat::source_test_teardown(".", env))

  lister <- testthat::ListReporter$new()
  lister$start_file("cucumber")
  run_error <- NULL
  withRestarts(
    testthat::with_reporter(lister, {
      tryCatch(
        run_cucumber(
          ".", filter, tags, reporter, strict, dry_run, name, features, fail_fast, retry, order, ...,
          cleanup_env = environment(),
          # Like a test file, each feature file is the file of its results
          start_file = \(feature) lister$start_file(as.character(fs::path_rel(feature, ".")))
        ),
        # Like an error of a test file, it's in the results
        error = function(e) {
          run_error <<- e
          lister$add_result(context = NULL, test = NULL, result = testthat::new_expectation("error", conditionMessage(e)))
          lister$end_context(NULL)
        }
      )
    }),
    cucumber_fail_test = function(error) stop(error)
  )
  result <- lister$get_results()
  results <- as.data.frame(result)
  if (stop_on_failure && (sum(results$failed) > 0 || any(results$error))) {
    # With the error that stopped the run, like a feature file that can't be parsed
    abort("Test failures.", parent = run_error, call = NULL, trace = empty_trace())
  }
  if (stop_on_warning && any(results$warning > 0)) {
    abort("Tests generated warnings.", call = NULL, trace = empty_trace())
  }
  invisible(result)
}

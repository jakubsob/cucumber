#' Run a feature's scenarios, reporting its document and pickles
#'
#' @param pickles The document's pickles
#' @importFrom purrr walk
#' @return Whether a scenario failed, invisibly
#' @keywords internal
#' @noRd
execute <- function(
  document,
  steps = get_steps(),
  parameters = get_parameters(),
  hooks = get_hooks(),
  tags = NULL,
  name = NULL,
  lines = integer(),
  feature_file = NULL,
  reporter = NULL,
  strict = TRUE,
  dry_run = FALSE,
  fail_fast = FALSE,
  retry = 0L,
  failed = FALSE,
  pickles = create_pickles(document, feature_file = feature_file)
) {
  checkmate::assert_list(steps)
  checkmate::assert_list(parameters, min.len = 1)
  checkmate::assert_list(hooks)

  emit(reporter, "gherkinDocument", document)
  walk(pickles, \(pickle) emit(reporter, "pickle", pickle$message))
  pickles <- prepare_pickles(pickles, steps, parameters, hooks, tags, name, lines, reporter)
  config <- run_config(".", NULL, tags, reporter, strict, dry_run, name, NULL, fail_fast, retry, "defined")
  execute_feature(document, pickles, hooks, config, failed = failed)
}

#' Choose the pickles to run, match their steps and plan their test cases
#'
#' Each pickle that runs gets a test case, reported before any scenario runs.
#'
#' @return The pickles to run
#' @keywords internal
#' @noRd
#' @importFrom purrr map walk
prepare_pickles <- function(
  pickles,
  steps = get_steps(),
  parameters = get_parameters(),
  hooks = get_hooks(),
  tags = NULL,
  name = NULL,
  lines = integer(),
  reporter = NULL,
  test_run_started_id = NULL
) {
  pickles <- pickles |>
    filter_pickles(tags, name, lines) |>
    match_steps(steps, parameters) |>
    map(\(pickle) new_test_case(pickle, hooks))
  walk(pickles, \(pickle) emit(reporter, "testCase", test_case_message(pickle, test_run_started_id)))
  pickles
}

#' Run the prepared pickles of a feature
#'
#' @param config The settings of the run, from `run_config()`
#' @param skip The skip of a before all hook, that skips every scenario, or `NULL`
#' @param snapshots The snapshots of the feature, from `run_snapshots()`, or
#'   `NULL` to leave snapshots to testthat
#' @return Whether a scenario failed, invisibly
#' @keywords internal
#' @noRd
#' @importFrom testthat context_start_file
execute_feature <- function(
  document,
  pickles,
  hooks,
  config,
  failed = FALSE,
  skip = NULL,
  snapshots = NULL
) {
  # A feature without scenarios to run isn't reported
  if (length(pickles) == 0) {
    return(invisible(failed))
  }

  # Set feature context for testthat
  context_start_file(feature_label(document$feature))

  # expect_snapshot() saves to the feature's snapshot file
  if (!is.null(snapshots)) withr::local_options(testthat.snapshotter = snapshots$snapshotter)
  execute_pickles(
    pickles,
    hooks,
    config,
    failed = failed,
    skip = skip,
    snapshots = snapshots
  )
}

#' The snapshot file of a feature file: its path relative to `path`, its
#' directories joined by `-`, without the `.md` of a feature file in Markdown,
#' so `checkout/basket.feature.md` has its snapshots in
#' `_snaps/checkout-basket.feature.md`. testthat's `_snaps` has a file for each
#' test file and a directory for each variant, and its snapshot_accept() and
#' snapshot_review() look one directory deep, so a directory of the feature
#' would read as a variant. Like testthat, it drops a `test-` prefix, so the
#' name is the one testthat's snapshotter uses.
#' @return The file's name in the `_snaps` directory of `path`
#' @keywords internal
#' @noRd
snapshot_file <- function(feature, path) {
  sub("^test[-_]", "", gsub("/", "-", sub("[.]md$", "", fs::path_rel(feature, path))))
}

#' The snapshots of a run's features, until the calling function returns
#'
#' Each feature that runs gets its snapshots when its first scenario runs, kept
#' until the run ends, as its scenarios may not run one after another, like in
#' random order. The snapshot files of the features in `path` are kept by
#' testthat's snapshotter of the test file that runs them, even of those that
#' don't run. Without one, like in test() of tests/acceptance, the run deletes the snapshot files
#' it didn't use, like testthat does at the end of its run.
#'
#' A run of some of the scenarios, or one that didn't finish, keeps every file
#' snapshot of the features, as testthat keeps those of the test files it
#' didn't run.
#' @param features The feature files in `path`
#' @param complete Whether every scenario runs, see `complete_run()`
#' @return A list with `feature()`, that gets the snapshots of a feature file
#'   from its file and the test names of all its scenarios, and `finish()`,
#'   called when every scenario ran
#' @keywords internal
#' @noRd
run_snapshots <- function(path, features, complete, frame = parent.frame()) {
  force(frame)
  dir <- fs::path(path, "_snaps")
  files <- snapshot_file(features, path)
  check_snapshot_files(fs::path_rel(features, path), files)
  outer <- getOption("testthat.snapshotter")
  # testthat's snapshotter cleans up only its own directory, so the run cleans
  # up the snapshots of feature files elsewhere, like `run("../acceptance")`
  if (!is.null(outer) && fs::path_abs(outer$snap_dir) != fs::path_abs(dir)) outer <- NULL
  # What the run used, for the run to delete the rest
  seen <- if (is.null(outer)) rlang::env(test_file_seen = character(), snap_file_seen = character())
  walk(files, \(file) keep_snapshot_files(outer %||% seen, file))
  finished <- FALSE
  withr::defer(
    {
      if (!complete || !finished) {
        walk(files, \(file) keep_snapshot_files(outer %||% seen, file, existing_snapshot_files(dir, file)))
      }
      if (!is.null(seen) && !env_var_is_true("CI")) delete_unused_snapshots(dir, seen)
    },
    envir = frame,
    priority = "last"
  )
  started <- list()
  list(
    feature = function(feature, test_names) {
      started[[feature]] <<- started[[feature]] %||%
        local_feature_snapshots(dir, snapshot_file(feature, path), outer %||% seen, frame, test_names)
      started[[feature]]
    },
    finish = function() finished <<- TRUE
  )
}

#' Whether a run runs every scenario: not with `filter`, `tags`, `name` or
#' `features`, and not in a dry run
#' @keywords internal
#' @noRd
complete_run <- function(filter, tags, name, features, dry_run) {
  is.null(filter) && is.null(tags) && is.null(name) && is.null(features) && !dry_run
}

#' Two feature files can't save their snapshots in the same file, like
#' `basket.feature` and `basket.feature.md`
#' @param features The feature files, relative to the directory of the run
#' @param files The snapshot file of each feature, from `snapshot_file()`
#' @keywords internal
#' @noRd
check_snapshot_files <- function(features, files) {
  shared <- unique(files[duplicated(files)])
  if (length(shared) == 0) {
    return(invisible())
  }
  body <- vapply(shared, \(file) {
    paste0(
      paste0("`", features[files == file], "`", collapse = " and "),
      " save their snapshots in `_snaps/", file, ".md`."
    )
  }, character(1))
  abort(
    "Feature files share a snapshot file.",
    body = c(rlang::set_names(body, "x"), i = "Rename one of them."),
    call = NULL,
    trace = empty_trace()
  )
}

#' The `expect_snapshot_file()` files of a feature's snapshot `file`, in its
#' directory and in the directories of variants, relative to them
#' @keywords internal
#' @noRd
existing_snapshot_files <- function(dir, file) {
  if (!fs::dir_exists(dir)) {
    return(character())
  }
  dirs <- fs::path(c(dir, fs::dir_ls(dir, type = "directory")), file)
  unique(unlist(lapply(dirs[fs::dir_exists(dirs)], \(d) {
    fs::path_rel(fs::dir_ls(d, recurse = TRUE, type = "file"), d)
  })))
}

#' Delete the snapshot files of features in `dir` the run didn't use: the
#' snapshot files of feature files that don't exist anymore, and of cucumber 2's
#' test(), and the
#' `expect_snapshot_file()` files that weren't taken, in the directory of a
#' feature's snapshot file and of its variants. The snapshots of testthat's
#' test files in `dir` aren't touched.
#' @param seen What the run used, like testthat's snapshotter
#'   `test_file_seen` and `snap_file_seen`
#' @keywords internal
#' @noRd
delete_unused_snapshots <- function(dir, seen) {
  if (!fs::dir_exists(dir)) {
    return(invisible())
  }
  files <- as.character(fs::path_rel(fs::dir_ls(dir, recurse = TRUE, type = "file"), dir))
  # And `__cucumber__.md`, where cucumber 2 saved the snapshots of test()
  features <- files[grepl("[.]feature([.]new)?[.]md$|[.]feature/|(^|/)__cucumber__([.]new)?[.]md$", files)]
  new_files <- paste0(tools::file_path_sans_ext(seen$snap_file_seen), ".new.", tools::file_ext(seen$snap_file_seen))
  expected <- c(
    paste0(seen$test_file_seen, ".md"),
    paste0(seen$test_file_seen, ".new.md"),
    seen$snap_file_seen,
    new_files
  )
  # A file in the directory of a variant, like `_snaps/linux/basket.feature.md`
  unused <- features[!features %in% expected & !sub("^[^/]+/", "", features) %in% expected]
  if (length(unused) > 0) {
    rlang::inform(paste0("Deleting unused snapshots: ", paste0("`", unused, "`", collapse = ", ")))
    fs::file_delete(fs::path(dir, unused))
  }
  # And the directories left empty, deepest first, like testthat
  for (d in c(sort(fs::dir_ls(dir, recurse = TRUE, type = "directory"), decreasing = TRUE), dir)) {
    if (length(fs::dir_ls(d, all = TRUE)) == 0) fs::dir_delete(d)
  }
  invisible()
}

env_var_is_true <- function(name) {
  isTRUE(as.logical(Sys.getenv(name, "false")))
}

#' Snapshots of a feature go to its own snapshot file, whether it runs in a
#' testthat file or in test(), written when `frame` ends
#'
#' The snapshotter is testthat's, the one a test file gets. testthat isn't told
#' the feature started, so its reporters still see the test file that runs it.
#' @param outer testthat's snapshotter of the test file, or what the run used,
#'   see `run_snapshots()`
#' @param test_names The test names of all the feature's scenarios
#' @return An environment with the `snapshotter` and the `scenarios` that ran,
#'   told of each scenario by `execute_single_pickle()`
#' @keywords internal
#' @noRd
local_feature_snapshots <- function(dir, file, outer, frame, test_names) {
  snapshotter <- testthat::local_snapshotter(dir, frame = frame)
  snapshotter$start_file(file)
  feature <- new.env()
  feature$snapshotter <- snapshotter
  feature$scenarios <- character()
  withr::defer(
    {
      # Scenarios that didn't run, like with `name` or `tags`, keep their snapshots,
      # skipped like a testthat test. Those of scenarios no longer in the feature
      # file are dropped, like the snapshots of a test removed from its test file.
      for (test in setdiff(paste("Scenario:", test_names), feature$scenarios)) skip_snapshot_test(snapshotter, test)
      # They keep their changed snapshots too, to review, like those another
      # run() of the feature found: testthat would rewrite the `.new.md` file
      # with the scenarios that ran
      file_snaps <- utils::getFromNamespace("FileSnaps", "testthat")
      changed <- file_snaps$new(dir, paste0(snapshotter$file, ".new"), type = "old")
      for (variant in changed$variants()) {
        kept <- setdiff(intersect(names(changed$snaps[[variant]]), paste("Scenario:", test_names)), feature$scenarios)
        for (test in kept) snapshotter$new_snaps$snaps[[variant]][[test]] <- changed$snaps[[variant]][[test]]
        if (length(kept) > 0) snapshotter$variants_changed <- union(snapshotter$variants_changed, variant)
      }
      # In the order of the scenarios in the feature file, whatever the order they ran in
      tests <- paste("Scenario:", test_names)
      for (snaps in list(snapshotter$cur_snaps, snapshotter$new_snaps)) {
        for (variant in names(snaps$snaps)) {
          snaps$snaps[[variant]] <- snaps$snaps[[variant]][order(match(names(snaps$snaps[[variant]]), tests))]
        }
      }
      snapshotter$end_file()
      # The files expect_snapshot_file() took are kept too. Like in testthat,
      # those of scenarios that didn't take them, like ones that didn't run,
      # are deleted unless announced with testthat::announce_snapshot_file()
      keep_snapshot_files(outer, snapshotter$file, fs::path_rel(snapshotter$snap_file_seen, snapshotter$file))
    },
    envir = frame,
    priority = "first"
  )
  feature
}

#' testthat's hint to accept or review a changed snapshot names the feature's
#' snapshot file, as it does for a test file, without the variant's directory
#' the snapshot is in: a variant's is `snapshot_accept("linux/basket.feature")`.
#' @param failure A failed expectation
#' @keywords internal
#' @noRd
variant_snapshot_hint <- function(failure) {
  variant <- regmatches(failure$message, regexec("has changed \\(variant '([^']+)'\\)", failure$message))[[1]][2]
  if (!is.na(variant)) {
    failure$message <- gsub(
      "(snapshot_(accept|review)\\(\")([^\"/]+\")", paste0("\\1", variant, "/\\3"), failure$message
    )
  }
  failure
}

#' A scenario starts: its snapshots are named after it
#' @keywords internal
#' @noRd
start_snapshot_scenario <- function(snapshots, test_name) {
  snapshotter <- snapshots$snapshotter
  snapshotter$start_test(NULL, test_name)
  snapshots$scenarios <- c(snapshots$scenarios, snapshotter$test)
  snapshots$variants_changed <- snapshotter$variants_changed
}

#' A scenario runs again: the snapshots of its failed attempt are dropped, so
#' the next attempt's snapshots are checked like the first
#' @keywords internal
#' @noRd
retry_snapshot_scenario <- function(snapshots) {
  snapshotter <- snapshots$snapshotter
  for (snaps in list(snapshotter$cur_snaps, snapshotter$new_snaps)) {
    for (variant in snaps$variants()) snaps$snaps[[variant]][[snapshotter$test]] <- NULL
  }
  snapshotter$variants_changed <- snapshots$variants_changed
}

#' A scenario ends: like a testthat test that errors or skips, a scenario that
#' didn't pass keeps the snapshots it didn't check, as its steps after the one
#' that didn't pass were skipped. So does a scenario whose snapshots weren't
#' checked, as on CRAN, where testthat skips the test.
#' @param on_cran Whether a snapshot of the scenario wasn't checked, as on CRAN
#' @keywords internal
#' @noRd
end_snapshot_scenario <- function(snapshots, status, on_cran = FALSE) {
  snapshotter <- snapshots$snapshotter
  if (status != "passed" || on_cran) skip_snapshot_test(snapshotter, snapshotter$test)
}

#' Tell the snapshotter a test skipped, so it keeps the test's snapshots that
#' weren't checked, as testthat's reporters do with a skipped test
#' @keywords internal
#' @noRd
skip_snapshot_test <- function(snapshotter, test) {
  snapshotter$start_test(NULL, test)
  snapshotter$add_result(NULL, test, testthat::new_expectation("skip", "The scenario didn't pass"))
}

#' Tell testthat's snapshotter of the test file, `outer`, that a feature's
#' snapshot `file` and the `names` of its expect_snapshot_file() files are
#' used, so it doesn't delete them at the end of its run. In a parallel
#' testthat run, which isn't supported, the snapshotter of the main process
#' isn't told, and deletes them.
#' @keywords internal
#' @noRd
keep_snapshot_files <- function(outer, file, names = character()) {
  outer$test_file_seen <- union(outer$test_file_seen, file)
  outer$snap_file_seen <- union(outer$snap_file_seen, fs::path(file, names))
  invisible()
}

#' Check the arguments that select the scenarios, see `test()`
#' @keywords internal
#' @noRd
check_selection <- function(path, filter, tags, name, features, ...) {
  if (!rlang::is_string(path) || !dir.exists(path)) {
    abort_user(
      "`path` must be a directory.",
      body = if (rlang::is_string(path)) c(x = paste0("\"", path, "\" doesn't exist."))
    )
  }
  check_tags(tags)
  check_grepl_args(...)
  if (!is.null(filter) && !rlang::is_string(filter)) {
    abort_user("`filter` must be one regular expression.")
  }
  check_regexps(filter, "`filter` must be a valid regular expression.", ...)
  if (!is.null(name) && !is.character(name)) {
    abort_user("`name` must be regular expressions.")
  }
  check_regexps(name, "`name` must be valid regular expressions.")
  if (!is.null(features) && !is.character(features)) {
    abort_user(
      "`features` must be paths of feature files.",
      body = c(i = "Give a path with the lines of its scenarios to run only them, like `\"basket.feature:12\"`.")
    )
  }
}

#' `...` of test() and run() is passed to grepl(), so a misspelled argument
#' would be ignored without a filter
#' @keywords internal
#' @noRd
check_grepl_args <- function(...) {
  allowed <- setdiff(names(formals(grepl)), c("pattern", "x"))
  unknown <- setdiff(names(list(...)), c(allowed, ""))
  if (length(unknown) > 0) {
    abort_user(
      paste0("Unknown argument", if (length(unknown) > 1) "s", ": ", paste0("`", unknown, "`", collapse = ", "), "."),
      body = c(i = paste0(
        "Arguments of `grepl()` for `filter` can be passed in `...`: ",
        paste0("`", allowed, "`", collapse = ", "), "."
      ))
    )
  }
}

#' Fail with `message` and the reason a regular expression is invalid
#' @param ... Arguments of `grepl()`, like `perl = TRUE`
#' @keywords internal
#' @noRd
check_regexps <- function(patterns, message, ...) {
  problems <- unlist(lapply(patterns, \(pattern) {
    tryCatch(
      {
        suppressWarnings(grepl(pattern, "", ...))
        NULL
      },
      error = conditionMessage
    )
  }))
  if (length(problems) > 0) {
    abort_user(
      message,
      body = rlang::set_names(problems, "x")
    )
  }
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
  # Like the empty lines of a rerun file
  features <- features[trimws(features) != ""]
  if (length(features) == 0) {
    return(list())
  }
  files <- sub("(:[0-9]+)*$", "", features)
  # Without the `./` of `path = "."`, like the feature files found in `path`
  files <- ifelse(fs::is_absolute_path(files), files, fs::path_norm(fs::path(path, files)))
  missing <- unique(files[!file_exists(files)])
  if (length(missing) > 0) {
    abort_user(
      "Feature files not found.",
      body = c(rlang::set_names(fs::path_norm(missing), "x"), i = "The paths in `features` are relative to `path`.")
    )
  }
  lines <- regmatches(features, regexpr("(:[0-9]+)*$", features)) |>
    strsplit(":") |>
    lapply(\(x) as.integer(x[x != ""]))
  # A directory runs all the feature files in it, whatever its lines
  expanded <- lapply(files, \(file) if (fs::is_dir(file)) find_features(file) else file)
  lines <- rep(ifelse(fs::is_dir(files), list(integer()), lines), lengths(expanded))
  files <- unlist(expanded, use.names = FALSE)
  # A factor keeps the files in the order they're given
  lapply(split(lines, factor(files, unique(files))), \(x) unique(unlist(x, use.names = FALSE)))
}

#' @importFrom fs dir_ls is_file
find_features <- function(path) {
  # A symbolic link to a feature file is run too
  features <- dir_ls(path, regexp = feature_file_pattern(), type = c("file", "symlink"), recurse = TRUE)
  # Snapshot files, like `_snaps/basket.feature.md`, aren't feature files
  features[is_file(features) & !grepl("(^|/)_snaps/", fs::path_rel(features, path))]
}

filter_features <- function(features, filter = NULL, ...) {
  if (is.null(filter)) {
    return(features)
  }
  features[grepl(filter, sub(feature_file_pattern(), "", fs::path_file(features)), ...)]
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
    abort_user(
      "No feature files found.",
      body = c(
        i = "Add `.feature` files describing your scenarios."
      )
    )
  }
  features
}

#' Keep the pickles selected by `tags`, any of the regular expressions in `name`,
#' and any of the `lines` of their feature file, see `test()`
#' @keywords internal
#' @noRd
filter_pickles <- function(pickles, tags = NULL, name = NULL, lines = integer()) {
  keep(pickles, \(pickle) {
    evaluate_tag_expression(tags, pickle$tags) &&
      (is.null(name) || any(vapply(name, grepl, logical(1), x = pickle$name))) &&
      (length(lines) == 0 || any(pickle$lines %in% lines))
  })
}

#' Check `order`, see `test()`. A random order without a seed gets one, shown
#' so the same order can be run again.
#' @return The order, with a seed if it's random
#' @keywords internal
#' @noRd
resolve_order <- function(order) {
  valid <- rlang::is_string(order) && grepl("^(defined|reverse|random(:[0-9]+)?)$", order) && {
    # A seed of set.seed(), an integer
    seed <- regmatches(order, regexec("^random:([0-9]+)$", order))[[1]][2]
    is.na(seed) || as.numeric(seed) <= .Machine$integer.max
  }
  if (!valid) {
    abort_user(
      paste0("Unknown order ", deparse1(order), "."),
      body = c(i = paste(
        "Use \"defined\", \"reverse\", \"random\" or \"random:<seed>\", like \"random:1234\",",
        "with a seed of up to 2147483647."
      ))
    )
  }
  if (order == "random") {
    # Without changing the session's random numbers
    order <- paste0("random:", withr::with_preserve_seed(sample.int(99999L, 1L)))
    rlang::inform(paste0(
      "Running scenarios in random order. Use `order = \"", order, "\"` to run them in this order again."
    ))
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

#' The scenarios of a run, in the order to run them: the pickles of the
#' features that are selected, ordered together
#' @param features The feature files that run
#' @param sources The parsed features by file, with their `pickles`
#' @param lines The lines of the scenarios to run of each feature file, see `feature_lines()`
#' @param config The settings of the run, from `run_config()`
#' @keywords internal
#' @noRd
#' @importFrom purrr map
select_pickles <- function(features, sources, lines, config) {
  pickles <- unlist(
    map(unname(features), \(path) filter_pickles(sources[[path]]$pickles, config$tags, config$name, lines[[path]])),
    recursive = FALSE
  )
  order_pickles(pickles, config$order)
}

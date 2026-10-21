# The samples of the Cucumber Compatibility Kit in tests/testthat/cck, see
# R/tools-update_cck.R. Each sample runs with CucumberMessagesReporter, and its
# messages must be the ones the CCK expects.
skip_if_not_installed("jsonlite")

read_ndjson <- function(path) {
  lapply(readLines(path, warn = FALSE, encoding = "UTF-8"), jsonlite::fromJSON, simplifyVector = FALSE)
}

#' The arguments a sample runs with, from its `.arguments.txt`, like
#' `--retry 2`, as arguments of test(): `list(retry = 2)`
sample_arguments <- function(sample) {
  file <- fs::dir_ls(sample, glob = "*.arguments.txt")
  if (length(file) == 0) {
    return(list())
  }
  words <- strsplit(trimws(readLines(file, warn = FALSE)), "\\s+")[[1]]
  values <- lapply(words[c(FALSE, TRUE)], utils::type.convert, as.is = TRUE)
  rlang::set_names(values, sub("^--", "", words[c(TRUE, FALSE)]))
}

#' Run a sample in a copy of its directory, with registries of its own
run_sample <- function(sample) {
  dir <- withr::local_tempdir()
  fs::dir_copy(sample, dir, overwrite = TRUE)
  output <- file.path(dir, "messages.ndjson")
  id <- as.character(runif(1))
  options <- paste0(c(".cucumber_steps_", ".cucumber_hooks_", ".cucumber_parameters_"), id)
  withr::local_options(list(
    .cucumber_steps_option = options[[1]],
    .cucumber_hooks_option = options[[2]],
    .cucumber_parameters_option = options[[3]],
    .cucumber_reporter = NULL
  ))
  withr::defer(options(rlang::set_names(vector("list", 3), options)))
  set_default_parameters()
  # Like the CCK, a run that fails is what some samples are about
  arguments <- sample_arguments(sample)
  try(rlang::exec(test, dir, reporter = CucumberMessagesReporter$new(output), stop_on_failure = FALSE, !!!arguments), silent = TRUE)
  read_ndjson(output)
}

# Fields that change between runs and implementations: where files are,
# when things happen, and how errors and snippets are written
IGNORED <- c("meta", "uri", "sourceReference", "timestamp", "duration", "message", "stackTrace")

ID_FIELDS <- c(
  "id", "astNodeId", "astNodeIds", "hookId", "pickleId", "pickleStepId", "stepDefinitionIds",
  "testRunStartedId", "testRunHookStartedId", "testCaseId", "testCaseStartedId", "testStepId"
)

# Samples whose step definitions return "pending" or "skipped". R signals
# pending() and skip_scenario() as conditions, like the pending-exception and
# skipped-exception samples, so their results have an exception too.
RETURNED_STATUSES <- c("failedish-combinations", "hooks-skipped", "pending", "retry-pending", "skipped", "skipped-failing-hook")

#' Messages without the fields that change, with their fields in alphabetical
#' order. Ids are numbered in the order they first appear, so they still have
#' to refer to the same messages.
normalize_messages <- function(messages, returned_statuses = FALSE) {
  ids <- character()
  rename <- function(id) {
    if (!id %in% names(ids)) ids[[id]] <<- paste0("id", length(ids))
    ids[[id]]
  }
  normalize <- function(x, name = "") {
    if (name %in% ID_FIELDS) {
      return(if (is.list(x)) lapply(x, rename) else rename(x))
    }
    if (!is.list(x)) {
      return(x)
    }
    if (name == "exception") {
      x$type <- NULL
    }
    if (name == "testStepResult" && returned_statuses && x$status %in% c("PENDING", "SKIPPED")) {
      x$exception <- NULL
    }
    if (name == "snippets") {
      return(lapply(x, \(snippet) list()))
    }
    if (!is.null(names(x))) {
      x <- x[setdiff(sort(names(x)), IGNORED)]
      return(Map(normalize, x, names(x)))
    }
    lapply(x, normalize)
  }
  messages <- Filter(\(message) is.null(message$meta), messages)
  normalize(messages)
}

describe("Cucumber Messages", {
  it("gives a run nested in another run ids of its own, and the outer run's ids continue after it", {
    ids$next_id <- 100L
    withr::defer(reset_ids())

    messages <- run_sample(test_path("cck", "minimal"))

    expect_equal(ids$next_id, 100L)
    expect_equal(messages[[4]]$pickle$id, "3")
  })
})

describe("the Cucumber Compatibility Kit", {
  for (sample in fs::dir_ls(test_path("cck"), type = "directory")) {
    it(paste("gives the messages of", fs::path_file(sample)), {
      expected <- read_ndjson(fs::dir_ls(sample, glob = "*.ndjson"))
      returned <- fs::path_file(sample) %in% RETURNED_STATUSES

      expect_equal(normalize_messages(run_sample(sample), returned), normalize_messages(expected, returned))
    })
  }
})

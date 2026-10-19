# Updates the samples of the Cucumber Compatibility Kit
# (https://github.com/cucumber/compatibility-kit) in tests/testthat/cck. It's
# internal, call it from the package root:
#
#   devtools::load_all()
#   update_cck()            # latest main
#   update_cck("v31.0.0")   # a tag or a commit
#
# Each sample is a directory with feature files and the messages a run of
# them must give, as NDJSON, and the files its steps attach. The CCK writes its step definitions in
# TypeScript (devkit/samples/<sample>/<sample>.ts); the R ones are ported by
# hand into tests/testthat/cck/<sample>/setup-steps.R, which this script
# keeps, like the sample's junit.xml, copied by update_junit_xml(). test-cck.R runs each sample with CucumberMessagesReporter and compares the
# messages with the CCK's.
#
# A new sample is copied only once it's added to CCK_SAMPLES, with its R
# step definitions. Samples are left out for what cucumber doesn't do yet:
#
# - markdown: Markdown with Gherkin
# - multiple-features-reversed: running features in reverse order
# - retry, retry-ambiguous, retry-pending, retry-undefined: retrying
#
# all-statuses and test-run-exception aren't test samples.

CCK_REPO <- "https://github.com/cucumber/compatibility-kit.git"

CCK_SAMPLES <- c(
  "ambiguous",
  "attachments",
  "backgrounds",
  "cdata",
  "data-tables",
  "data-tables-doc-strings",
  "data-tables-with-expression",
  "doc-strings",
  "doc-strings-with-expression",
  "empty",
  "examples-tables",
  "examples-tables-attachment",
  "examples-tables-undefined",
  "examples-tables-undefined-multiple",
  "failedish-combinations",
  "global-hooks",
  "global-hooks-afterall-error",
  "global-hooks-attachments",
  "global-hooks-beforeall-error",
  "hooks",
  "hooks-attachment",
  "hooks-conditional",
  "hooks-named",
  "hooks-skipped",
  "hooks-undefined",
  "minimal",
  "multiple-features",
  "parameter-types",
  "pending",
  "pending-exception",
  "regular-expression",
  "rules",
  "rules-backgrounds",
  "skipped",
  "skipped-exception",
  "skipped-failing-hook",
  "stack-traces",
  "undefined",
  "undefined-multiple",
  "unknown-parameter-type",
  "unused-steps"
)

# Directories renamed so paths stay under the 100 bytes R CMD check allows
CCK_DIRECTORIES <- c("examples-tables-undefined-multiple" = "examples-undefined-multiple")

#' Update the Cucumber Compatibility Kit samples
#'
#' See the comment at the top of R/tools-update_cck.R.
#'
#' @param ref Branch, tag or commit of https://github.com/cucumber/compatibility-kit.
#' @param pkg Path to the package source.
#' @keywords internal
#' @noRd
update_cck <- function(ref = "main", pkg = ".") {
  repo <- file.path(tempdir(), "compatibility-kit")
  unlink(repo, recursive = TRUE)
  run_git("clone", "--quiet", "--filter=blob:none", CCK_REPO, repo)
  run_git("-C", repo, "checkout", "--quiet", ref)
  commit <- run_git("-C", repo, "rev-parse", "--short", "HEAD")

  to <- file.path(pkg, "tests", "testthat", "cck")
  for (sample in CCK_SAMPLES) {
    from <- file.path(repo, "devkit", "samples", sample)
    # The TypeScript step definitions are ported by hand
    files <- setdiff(list.files(from), list.files(from, pattern = "\\.ts$"))
    directory <- if (sample %in% names(CCK_DIRECTORIES)) CCK_DIRECTORIES[[sample]] else sample
    long <- paste0("cucumber/tests/testthat/cck/", directory, "/", files)
    long <- long[nchar(long, type = "bytes") > 100]
    if (length(long) > 0) {
      stop("Paths over 100 bytes, add a rename to CCK_DIRECTORIES:\n", paste(long, collapse = "\n"))
    }

    out <- file.path(to, directory)
    dir.create(out, recursive = TRUE, showWarnings = FALSE)
    unlink(setdiff(list.files(out, full.names = TRUE), file.path(out, c("setup-steps.R", "junit.xml"))))
    if (!all(file.copy(file.path(from, files), file.path(out, files)))) {
      stop("Can't copy the files of the sample ", sample)
    }
    if (!file.exists(file.path(out, "setup-steps.R"))) {
      message("Port the step definitions of ", sample, " to ", file.path(out, "setup-steps.R"))
    }
  }
  file.copy(file.path(repo, "LICENSE"), file.path(to, "LICENSE"), overwrite = TRUE)
  writeLines(
    c(
      "The samples of the Cucumber Compatibility Kit (https://github.com/cucumber/compatibility-kit),",
      paste0("commit ", commit, ", copied by update_cck() in R/tools-update_cck.R.")
    ),
    file.path(to, "README")
  )

  testthat::test_local(pkg, filter = "cck")
}

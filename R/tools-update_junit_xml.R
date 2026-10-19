# nocov start
# Updates the JUnit XML each sample of the Cucumber Compatibility Kit, in
# tests/testthat/cck, must be reported as: the test data of the official
# JUnit XML formatter (https://github.com/cucumber/junit-xml-formatter),
# testdata/src/<sample>.default.xml, copied to tests/testthat/cck/<sample>/junit.xml.
# It's internal, call it from the package root:
#
#   devtools::load_all()
#   update_junit_xml()            # latest main
#   update_junit_xml("v0.9.0")    # a tag or a commit
#
# test-reporter-junit.R reports each sample with CucumberJunitReporter and
# compares the XML with the formatter's.

JUNIT_XML_REPO <- "https://github.com/cucumber/junit-xml-formatter.git"

#' Update the JUnit XML of the Cucumber Compatibility Kit samples
#'
#' See the comment at the top of R/tools-update_junit_xml.R.
#'
#' @param ref Branch, tag or commit of https://github.com/cucumber/junit-xml-formatter.
#' @param pkg Path to the package source.
#' @keywords internal
#' @noRd
update_junit_xml <- function(ref = "main", pkg = ".") {
  repo <- file.path(tempdir(), "junit-xml-formatter")
  unlink(repo, recursive = TRUE)
  run_git("clone", "--quiet", "--filter=blob:none", JUNIT_XML_REPO, repo)
  run_git("-C", repo, "checkout", "--quiet", ref)
  commit <- run_git("-C", repo, "rev-parse", "--short", "HEAD")

  to <- file.path(pkg, "tests", "testthat", "cck")
  for (sample in CCK_SAMPLES) {
    from <- file.path(repo, "testdata", "src", paste0(sample, ".default.xml"))
    directory <- if (sample %in% names(CCK_DIRECTORIES)) CCK_DIRECTORIES[[sample]] else sample
    if (!file.copy(from, file.path(to, directory, "junit.xml"), overwrite = TRUE)) {
      stop("Can't copy the JUnit XML of the sample ", sample)
    }
  }
  file.copy(file.path(repo, "LICENSE"), file.path(to, "LICENSE-junit-xml-formatter"), overwrite = TRUE)
  writeLines(
    c(
      "The junit.xml of each sample is the test data of the official JUnit XML formatter",
      "(https://github.com/cucumber/junit-xml-formatter),",
      paste0("commit ", commit, ", copied by update_junit_xml() in R/tools-update_junit_xml.R.")
    ),
    file.path(to, "README-junit-xml-formatter")
  )

  testthat::test_local(pkg, filter = "reporter-junit")
}
# nocov end

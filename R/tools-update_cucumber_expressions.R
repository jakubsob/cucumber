# nocov start
# Updates the test data of the official Cucumber Expressions
# (https://github.com/cucumber/cucumber-expressions/tree/main/testdata/cucumber-expression)
# in tests/testthat/cucumber-expressions. It's internal, call it from the
# package root:
#
#   devtools::load_all()
#   update_cucumber_expressions()            # latest main
#   update_cucumber_expressions("v18.0.1")   # a tag or a commit
#
# The test data is a YAML file for each case, of which
# test-cucumber_expressions.R uses the matching ones, an expression and a text
# with the arguments it gives or the error, and the tokenizer and parser ones
# that are errors. Each directory is copied as one JSON file, with the cases by
# file name, so the tests read it with jsonlite and paths stay under the 100
# bytes R CMD check allows.

CUCUMBER_EXPRESSIONS_REPO <- "https://github.com/cucumber/cucumber-expressions.git"

#' Update the Cucumber Expressions test data
#'
#' See the comment at the top of R/tools-update_cucumber_expressions.R.
#'
#' @param ref Branch, tag or commit of https://github.com/cucumber/cucumber-expressions.
#' @param pkg Path to the package source.
#' @keywords internal
#' @noRd
update_cucumber_expressions <- function(ref = "main", pkg = ".") {
  rlang::check_installed(c("yaml", "jsonlite"), "to update the Cucumber Expressions test data.")
  repo <- file.path(tempdir(), "cucumber-expressions")
  unlink(repo, recursive = TRUE)
  run_git("clone", "--quiet", "--filter=blob:none", CUCUMBER_EXPRESSIONS_REPO, repo)
  run_git("-C", repo, "checkout", "--quiet", ref)
  commit <- run_git("-C", repo, "rev-parse", "--short", "HEAD")

  to <- file.path(pkg, "tests", "testthat", "cucumber-expressions")
  dir.create(to, recursive = TRUE, showWarnings = FALSE)
  for (kind in c("matching", "tokenizer", "parser")) {
    files <- list.files(
      file.path(repo, "testdata", "cucumber-expression", kind),
      pattern = "\\.yaml$", full.names = TRUE
    )
    # Numbers are doubles, as an integer like 9223372036854775807 is out of R's range
    cases <- lapply(files, yaml::read_yaml, handlers = list(int = as.numeric))
    names(cases) <- sub("\\.yaml$", "", basename(files))
    # Only the errors of the tokenizer and the parser, their tokens and syntax trees are internal
    if (kind != "matching") cases <- Filter(\(case) !is.null(case$exception), cases)
    # Arguments are a JSON array, also when there is one
    cases <- lapply(cases, \(case) {
      if (!is.null(case$expected_args)) case$expected_args <- I(as.list(case$expected_args))
      case
    })
    jsonlite::write_json(
      cases, file.path(to, paste0(kind, ".json")),
      auto_unbox = TRUE, digits = NA, null = "null", pretty = TRUE
    )
  }
  file.copy(file.path(repo, "LICENSE"), file.path(to, "LICENSE"), overwrite = TRUE)
  writeLines(
    c(
      "The test data of Cucumber Expressions (https://github.com/cucumber/cucumber-expressions),",
      paste0("commit ", commit, ", copied by update_cucumber_expressions() in R/tools-update_cucumber_expressions.R.")
    ),
    file.path(to, "README")
  )

  testthat::test_local(pkg, filter = "cucumber_expressions")
}
# nocov end

# nocov start
# Updates the JSON schema of Cucumber Messages
# (https://github.com/cucumber/messages) in tests/testthat/messages-schema,
# which the tests check every message CucumberMessagesReporter writes against.
# It's internal, call it from the package root:
#
#   devtools::load_all()
#   update_messages_schema()   # the version of PROTOCOL_VERSION
#
# It copies jsonschema/src/*.schema.json, one file per message, with two
# changes so jsonvalidate can resolve their references: it drops `$id`, so
# each schema is known by its file name, and the `./` of `$ref`, which
# jsonvalidate keeps in the name it gives the file.

MESSAGES_REPO <- "https://github.com/cucumber/messages.git"

#' Update the JSON schema of Cucumber Messages
#'
#' See the comment at the top of R/tools-update_messages_schema.R.
#'
#' @param ref Branch, tag or commit of https://github.com/cucumber/messages.
#' @param pkg Path to the package source.
#' @keywords internal
#' @noRd
update_messages_schema <- function(ref = paste0("v", PROTOCOL_VERSION), pkg = ".") {
  repo <- file.path(tempdir(), "messages")
  unlink(repo, recursive = TRUE)
  run_git("clone", "--quiet", "--filter=blob:none", MESSAGES_REPO, repo)
  run_git("-C", repo, "checkout", "--quiet", ref)
  commit <- run_git("-C", repo, "rev-parse", "--short", "HEAD")

  to <- file.path(pkg, "tests", "testthat", "messages-schema")
  unlink(to, recursive = TRUE)
  dir.create(to, recursive = TRUE)
  for (from in list.files(file.path(repo, "jsonschema", "src"), "\\.schema\\.json$", full.names = TRUE)) {
    schema <- readLines(from, warn = FALSE, encoding = "UTF-8")
    schema <- grep('^\\s*"\\$id":', schema, value = TRUE, invert = TRUE)
    schema <- sub('("\\$ref": ")\\./', "\\1", schema)
    writeLines(schema, file.path(to, basename(from)), useBytes = TRUE)
  }
  file.copy(file.path(repo, "LICENSE"), file.path(to, "LICENSE"), overwrite = TRUE)
  writeLines(
    c(
      "The JSON schema of Cucumber Messages (https://github.com/cucumber/messages),",
      paste0("commit ", commit, " (", ref, "), copied by update_messages_schema() in R/tools-update_messages_schema.R.")
    ),
    file.path(to, "README")
  )

  testthat::test_local(pkg, filter = "cck|gherkin")
}
# nocov end

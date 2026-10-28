# The good and bad files of the official Gherkin test data
# (https://github.com/cucumber/gherkin/tree/main/testdata), with the source,
# document, pickles and errors the official parser gives.
skip_if_not_installed("jsonlite")

read_ndjson <- function(path) {
  lapply(readLines(path, warn = FALSE, encoding = "UTF-8"), jsonlite::fromJSON, simplifyVector = FALSE)
}

#' A message as it reads from NDJSON, with its fields in alphabetical order
#' and without the uri, which is relative to another directory in the test data
normalize <- function(x) {
  if (!is.list(x)) {
    return(x)
  }
  if (!is.null(names(x))) {
    x <- x[setdiff(sort(names(x)), "uri")]
  }
  lapply(x, normalize)
}

as_read <- function(message) {
  normalize(jsonlite::fromJSON(envelope_json(message), simplifyVector = FALSE))
}

describe("parse_gherkin", {
  for (path in fs::dir_ls(test_path("gherkin", "good"), regexp = feature_file_pattern())) {
    expected <- function(kind) normalize(read_ndjson(paste0(path, ".", kind, ".ndjson")))

    it(paste("gives the official source for", fs::path_file(path)), {
      expect_equal(as_read(list(source = source_message(path))), expected("source")[[1]])
    })

    it(paste("gives the official document and pickles for", fs::path_file(path)), {
      local_ids()
      document <- parse_gherkin(read_feature(path), uri = path)
      pickles <- create_pickles(document)

      expect_equal(as_read(list(gherkinDocument = document)), expected("ast")[[1]])
      expect_equal(lapply(pickles, \(pickle) as_read(list(pickle = pickle$message))), expected("pickles"))
    })
  }

  for (path in fs::dir_ls(test_path("gherkin", "bad"), glob = "*.feature")) {
    it(paste("gives the official errors for", fs::path_file(path)), {
      errors <- read_ndjson(paste0(path, ".errors.ndjson")) |>
        vapply(\(message) message$parseError$message, character(1))

      error <- expect_error(parse_gherkin(read_feature(path)), class = "cucumber_parse_error")

      expect_equal(error$errors, errors)
    })
  }

  it("reports every error with the file path", {
    lines <- c("Feature: Broken", "  Scenario: Junk", "    Given a step", "    not a step", "    Given a step", "    also not a step")

    expect_snapshot(parse_gherkin(lines, uri = "features/broken.feature"), error = TRUE)
  })
})

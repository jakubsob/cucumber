# The good and bad files of the official Gherkin test data
# (https://github.com/cucumber/gherkin/tree/main/testdata), with the pickles
# and errors the official parser gives.
skip_if_not_installed("jsonlite")

read_ndjson <- function(path) {
  lapply(readLines(path, warn = FALSE), jsonlite::fromJSON, simplifyVector = FALSE)
}

official_pickles <- function(path) {
  read_ndjson(path) |>
    lapply(\(message) {
      pickle <- message$pickle
      list(
        name = pickle$name,
        line = pickle$location$line,
        tags = vapply(pickle$tags, \(tag) sub("^@", "", tag$name), character(1)),
        steps = lapply(pickle$steps, \(step) {
          docstring <- step$argument$docString
          table <- step$argument$dataTable
          list(
            text = step$text,
            type = step$type,
            docstring = if (!is.null(docstring)) {
              structure(strsplit(docstring$content, "\n")[[1]], media_type = docstring$mediaType)
            },
            table = if (!is.null(table)) {
              lapply(table$rows, \(row) vapply(row$cells, \(cell) cell$value, character(1)))
            }
          )
        })
      )
    })
}

compiled_pickles <- function(path) {
  read_feature(path) |>
    parse_gherkin(uri = path) |>
    create_pickles() |>
    lapply(\(pickle) {
      list(
        name = pickle$name,
        line = pickle$source_line,
        tags = pickle$tags,
        steps = lapply(pickle$steps, \(step) {
          table <- step$data_table
          list(
            text = step$text,
            type = step$type,
            docstring = step$docstring,
            table = if (!is.null(table)) {
              c(list(names(table)), lapply(seq_len(nrow(table)), \(i) unname(unlist(table[i, ]))))
            }
          )
        })
      )
    })
}

describe("parse_gherkin", {
  for (path in fs::dir_ls(test_path("gherkin", "good"), glob = "*.feature")) {
    it(paste("gives the official pickles for", fs::path_file(path)), {
      expect_equal(
        compiled_pickles(path),
        official_pickles(paste0(path, ".pickles.ndjson"))
      )
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

# Tables in the acceptance features, including the ones in doc strings,
# have their columns padded to equal widths.
# Not a Gherkin formatter or linter: they see a doc string as opaque text, so
# they'd miss the tables in the feature files the acceptance tests embed, and
# they'd add a non-R tool to CI and impose a whole formatting style.

#' Positions of the cell separators in a table row, skipping escaped pipes
pipe_positions <- function(line) {
  chars <- strsplit(line, "")[[1]]
  escaped <- c(FALSE, chars[-length(chars)] == "\\")
  which(chars == "|" & !escaped)
}

#' The first line of every table whose separators don't line up.
#' A table with rows of different cell counts is left alone, it's ragged on purpose.
misaligned_tables <- function(path) {
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  is_row <- grepl("^\\s*\\|", lines)
  tables <- split(which(is_row), cumsum(!is_row)[is_row])
  misaligned <- purrr::keep(tables, function(rows) {
    positions <- lapply(lines[rows], pipe_positions)
    length(unique(lengths(positions))) == 1 && length(unique(positions)) > 1
  })
  purrr::map_chr(unname(misaligned), \(rows) paste0(fs::path_file(path), ":", rows[1]))
}

describe("acceptance features", {
  it("have aligned tables", {
    paths <- fs::dir_ls(test_path("..", "acceptance"), regexp = "\\.feature$")
    expect_gt(length(paths), 0)
    expect_equal(unlist(lapply(paths, misaligned_tables), use.names = FALSE), character(0))
  })
})

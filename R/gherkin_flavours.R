#' The flavours of Gherkin a feature file can be written in, told apart by
#' the extension of the file. Each says how its documents are read and shown:
#'
#' - `extension` of its files.
#' - `media_type` of its sources in Cucumber Messages.
#' - `matchers` that classify its lines for the parser's state machine.
#' - `block_end`: a regular expression of the lines a part of a feature, like
#'   a scenario, doesn't end with in `features_rd()`, like blank lines and comments.
#' - `block_code`: a function of a feature's lines and the column of its
#'   keyword, giving them as they are shown in `features_rd()`.
#'
#' A function and not a constant, as the matchers are defined in other files.
#' @keywords internal
#' @noRd
gherkin_flavours <- function() {
  list(
    # Tried first, as its extension ends with the other one's
    markdown = list(
      extension = ".feature.md",
      media_type = "text/x.cucumber.gherkin+markdown",
      matchers = MARKDOWN_TOKEN_MATCHERS,
      # `#` starts a header, not a comment
      block_end = "^\\s*$",
      # Indentation tells a Gherkin table from a Markdown one
      block_code = \(code, column) code
    ),
    gherkin = list(
      extension = ".feature",
      media_type = "text/x.cucumber.gherkin+plain",
      matchers = TOKEN_MATCHERS,
      block_end = "^\\s*(#.*)?$",
      # Without the indent of the block's keyword
      block_code = \(code, column) sub(paste0("^ {0,", column - 1, "}"), "", code)
    )
  )
}

#' The flavour of a feature file, see `gherkin_flavours()`. A document
#' without a file is plain Gherkin.
#' @keywords internal
#' @noRd
gherkin_flavour <- function(uri = NULL) {
  flavours <- gherkin_flavours()
  for (flavour in flavours) {
    if (!is.null(uri) && endsWith(uri, flavour$extension)) {
      return(flavour)
    }
  }
  flavours$gherkin
}

#' A regular expression of the paths of feature files, of any flavour
#' @keywords internal
#' @noRd
feature_file_pattern <- function() {
  extensions <- vapply(gherkin_flavours(), \(flavour) flavour$extension, character(1))
  paste0("(", paste(gsub(".", "[.]", extensions, fixed = TRUE), collapse = "|"), ")$")
}

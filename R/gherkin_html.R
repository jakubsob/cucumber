#' HTML of lines of Gherkin, highlighted, as a pkgdown code block: on one
#' line, as pkgdown splits a section into paragraphs at blank lines, even in
#' \out, and with `</pre >`, not ending the HTML block of `gherkin_rd()`
#' @param lines Their numbers in the document of `tokens`
#' @param tokens Of `gherkin_tokens()`
#' @keywords internal
#' @noRd
gherkin_pre <- function(code, lines, tokens) {
  paste0(
    "<pre class=\"gherkin\"><code>",
    rd_escape(paste(gherkin_html(code, lines, tokens), collapse = "&#10;")),
    "</code></pre >"
  )
}

#' The lines of a document's tokens that pandoc's highlighting classes are for
#' @param source The lines of the feature file
#' @return A list of `keywords`, the keyword of a line and its classes by the
#'   line, and the lines of `comments` and of Doc `strings`
#' @keywords internal
#' @noRd
gherkin_tokens <- function(document, source) {
  keywords <- list()
  strings <- integer()
  walk <- function(node) {
    if (!is.list(node)) {
      return()
    }
    if (!is.null(node$keyword) && !is.null(node$location)) {
      # Only steps have a keywordType, and their keyword ends with its space
      keywords[[as.character(node$location$line)]] <<- if (is.null(node$keywordType)) {
        c(paste0(node$keyword, ":"), "kw")
      } else {
        c(trimws(node$keyword, "right"), "fu")
      }
    }
    doc <- node$docString
    if (!is.null(doc)) {
      from <- doc$location$line
      to <- min(which(trimws(source) == doc$delimiter & seq_along(source) > from))
      strings <<- c(strings, from:to)
    }
    for (child in node) walk(child)
  }
  walk(document$feature)
  list(keywords = keywords, strings = strings, comments = map_int(document$comments, \(comment) comment$location$line))
}

#' HTML of lines of a feature file, with the classes pandoc gives tokens, for
#' pkgdown's theme to highlight
#' @param text The lines
#' @param lines Their numbers in the feature file
#' @param tokens Of `gherkin_tokens()`
#' @keywords internal
#' @noRd
gherkin_html <- function(text, lines, tokens) {
  escape <- \(x) gsub(">", "&gt;", gsub("<", "&lt;", gsub("&", "&amp;", x, fixed = TRUE), fixed = TRUE), fixed = TRUE)
  span <- \(class, x) paste0("<span class=\"", class, "\">", x, "</span>")
  inline <- function(x) {
    x <- gsub("(\"[^\"]*\")", span("st", "\\1"), escape(x))
    x <- gsub("(&lt;[^&[:space:]]+&gt;)", span("va", "\\1"), x)
    gsub("(^|\\s)\\|(?=\\s|$)", paste0("\\1", span("op", "|")), x, perl = TRUE)
  }
  map_chr(seq_along(text), \(i) {
    if (lines[[i]] %in% tokens$comments) {
      return(span("co", escape(text[[i]])))
    }
    if (lines[[i]] %in% tokens$strings) {
      return(span("st", escape(text[[i]])))
    }
    keyword <- tokens$keywords[[as.character(lines[[i]])]]
    if (is.null(keyword)) {
      return(inline(text[[i]]))
    }
    # After the indent, or in Markdown after `## ` or `* `
    at <- regexpr(keyword[[1]], text[[i]], fixed = TRUE)
    before <- substring(text[[i]], 1, at - 1)
    rest <- substring(text[[i]], at + nchar(keyword[[1]]))
    paste0(escape(before), span(keyword[[2]], escape(keyword[[1]])), inline(rest))
  })
}

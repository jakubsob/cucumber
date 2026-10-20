#' Scenarios as documentation
#'
#' @description
#' Put scenarios of your feature files in the help page of a function, so that readers
#' of the help find how it behaves. Call it with `@eval` in the function's roxygen block:
#'
#' ```r
#' #' Add items to a basket
#' #' @eval cucumber::features_rd(features = "basket.feature")
#' #' @export
#' add <- function(basket, n) basket + n
#' ```
#'
#' It adds a section, "Specification" by default, with each selected feature: its name, its description,
#' the Backgrounds of the selected scenarios and the scenarios as they are written, without
#' their tags. Of a Scenario Outline, only the selected Examples rows are shown.
#'
#' Scenarios are selected like in [test()]. By default only scenarios tagged `@rd` are
#' selected, so that you choose the ones that make good documentation. Set the
#' `cucumber.rd_tags` option to use another tag expression, or pass `tags = NULL` to select
#' scenarios without a tag.
#'
#' It turns on markdown for the roxygen block it's in.
#'
#' @param path Path to the directory containing the `.feature` files. Its subdirectories are
#'   searched too. Defaults to the `cucumber.path` option, or `"tests/acceptance"` if it's not set.
#'   Relative paths are relative to the working directory, the package's root when you
#'   run `devtools::document()`.
#' @param filter If not NULL, only features with file names matching this regular expression
#'   are documented. Matching is performed on the file name after it's stripped of ".feature".
#' @param tags If not NULL, select scenarios by tag expression string, see [test()].
#'   Defaults to the `cucumber.rd_tags` option, or `"@rd"` if it's not set.
#' @param name If not NULL, only scenarios with names matching any of these regular expressions
#'   are documented.
#' @param features If not NULL, only these feature files are documented. Relative paths are
#'   relative to `path`. Add `:line` to select only the scenario at that line, e.g.
#'   `"addition.feature:12"`. The line of an example row selects only that example.
#' @param section Name of the section. Defaults to the `cucumber.rd_section` option, or
#'   `"Specification"` if it's not set.
#' @param ... Additional arguments passed to `grepl()`.
#' @return Lines of roxygen tags, for `@eval`.
#'
#' @eval features_rd(features = "r-features_rd.feature")
#'
#' @export
#' @md
features_rd <- function(
  path = getOption("cucumber.path", "tests/acceptance"),
  filter = NULL,
  tags = getOption("cucumber.rd_tags", "@rd"),
  name = NULL,
  features = NULL,
  section = getOption("cucumber.rd_section", "Specification"),
  ...
) {
  checkmate::assert_string(section, min.chars = 1)
  check_grepl_args(...)
  lines <- feature_lines(features, path)
  files <- select_features(path, filter, lines, ...)
  sources <- parse_features(files)
  rd <- unlist(map(files, \(file) {
    pickles <- filter_pickles(sources[[file]]$pickles, tags, name, lines[[file]])
    feature_rd(sources[[file]]$document, pickles, read_feature(file), file)
  }))
  if (length(rd) == 0) {
    abort(
      "No scenarios to document.",
      body = c(i = paste0("Tag the scenarios with `", tags %||% "@rd", "`, or select them with other arguments.")),
      trace = empty_trace()
    )
  }
  c("@md", paste0("@section ", section, ":"), rd)
}

#' Markdown of a feature with its selected scenarios, written as in its source
#'
#' @param pickles The selected pickles of the document
#' @param source The lines of the feature file
#' @return Lines of markdown, or NULL if no scenario is selected
#' @importFrom purrr map map_int
#' @keywords internal
#' @noRd
feature_rd <- function(document, pickles, source, file) {
  if (length(pickles) == 0) {
    return(NULL)
  }
  feature <- document$feature
  # The scenarios and the outline rows that are selected
  selected <- unlist(map(pickles, \(pickle) pickle$message$astNodeIds))
  # A child of the feature or of a rule ends before the first line of the next one
  starts <- c(unlist(map(c(feature$children, unlist(map(feature$children, \(child) child$rule$children), recursive = FALSE)), \(child) {
    node <- child$background %||% child$scenario %||% child$rule
    first_line(node)
  })), length(source) + 1)
  block <- function(node, drop = integer()) {
    from <- node$location$line
    to <- min(starts[starts > from]) - 1
    lines <- setdiff(from:to, drop)
    # Without the blank lines and comments before the next child
    while (length(lines) > 0 && grepl("^\\s*(#.*)?$", source[[lines[[length(lines)]]]])) {
      lines <- lines[-length(lines)]
    }
    code <- sub(paste0("^ {0,", node$location$column - 1, "}"), "", source[lines])
    # Rd, not a markdown code block: pkgdown empties code blocks of a language
    # pandoc can't highlight, like gherkin, and highlights the others as R. In
    # HTML it's a gherkin block, as in a markdown page, for the site's script
    # to highlight
    rd_escape <- \(x) gsub("([{}%])", "\\\\\\1", gsub("\\", "\\\\", x, fixed = TRUE))
    html <- gsub(">", "&gt;", gsub("<", "&lt;", gsub("&", "&amp;", code, fixed = TRUE), fixed = TRUE), fixed = TRUE)
    html <- rd_escape(html)
    # pkgdown splits a section into paragraphs at blank lines, even in \out,
    # and joins the lines around them, so a blank line gets an empty element
    html[grepl("^\\s*$", html)] <- "<span></span>"
    html[[1]] <- paste0("<pre class=\"gherkin\"><code>", html[[1]])
    # roxygen evaluates `r ` code of the markdown before it reads Rd, so a
    # ```r Doc String and the backticks of a description would make R code.
    # Markdown isn't read in an HTML block, from a line starting with <pre to
    # a line with </pre>: both copies are in one, ended by an Rd comment
    html[[length(html)]] <- paste0(html[[length(html)]], "</code></pre >}}")
    code <- rd_escape(code)
    code[[1]] <- paste0("\\if{text,latex}{\\preformatted{", code[[1]])
    c("\\if{html}{\\out{", html, code, "%</pre>", "}}", "")
  }
  scenario_block <- function(scenario) {
    if (is.null(scenario) || !scenario$id %in% selected) {
      return(NULL)
    }
    # Without the Examples' tags, like the scenario's
    drop <- unlist(map(scenario$examples, \(examples) {
      c(map_int(examples$tags, \(tag) tag$location$line), unselected_rows(examples, selected))
    }))
    block(scenario, drop)
  }
  children_rd <- function(children) {
    scenarios <- unlist(map(children, \(child) scenario_block(child$scenario)))
    rules <- unlist(map(children, \(child) if (!is.null(child$rule)) rule_rd(child$rule)))
    if (length(scenarios) == 0 && length(rules) == 0) {
      return(NULL)
    }
    background <- Find(\(child) !is.null(child$background), children)$background
    c(if (!is.null(background)) block(background), scenarios, rules)
  }
  rule_rd <- function(rule) {
    rd <- children_rd(rule$children)
    if (is.null(rd)) {
      return(NULL)
    }
    c(paste0("**", rule$keyword, ": ", escape_braces(rule$name), "**"), "", description_rd(rule$description), rd)
  }
  c(
    paste0("## ", escape_braces(if (nzchar(feature$name)) feature$name else feature$keyword)),
    "",
    description_rd(feature$description),
    children_rd(feature$children),
    paste0("Source: `", file, "`"),
    ""
  )
}

#' The first line of a node: of its tags, or of its keyword
#' @keywords internal
#' @noRd
first_line <- function(node) {
  min(node$location$line, unlist(map(node$tags, \(tag) tag$location$line)))
}

#' The lines of an Examples that aren't selected: its rows that aren't, or all
#' its lines if none of its rows is
#' @keywords internal
#' @noRd
unselected_rows <- function(examples, selected) {
  rows <- examples$tableBody
  kept <- vapply(rows, \(row) row$id %in% selected, logical(1))
  if (any(kept)) {
    return(map_int(rows[!kept], \(row) row$location$line))
  }
  last <- if (length(rows) > 0) rows[[length(rows)]] else examples$tableHeader
  seq(first_line(examples), last$location$line %||% examples$location$line)
}

#' Escape the braces of markdown text, which Rd would read as a group. roxygen
#' escapes the rest.
#' @keywords internal
#' @noRd
escape_braces <- function(x) {
  gsub("([{}])", "\\\\\\1", x)
}

description_rd <- function(description) {
  if (!nzchar(description)) {
    return(NULL)
  }
  c(trimws(strsplit(description, "\n")[[1]]), "")
}

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
#' It adds a section, named `r format_option_default("cucumber.rd_section")` by default,
#' with each selected feature: its name, its description, the Rules and Backgrounds of the
#' selected scenarios and the scenarios, without their tags. Of a Scenario Outline, only the
#' selected Examples rows are shown.
#'
#' In the help page, each feature is one block of Gherkin, as it's written. On HTML pages,
#' like the pkgdown reference page, it's shown like Markdown with Gherkin: the names of the
#' feature and of its Rules, Backgrounds, scenarios and Examples are headers, steps are a
#' list, tables are tables and Doc Strings are code, a Doc String of Gherkin highlighted as
#' Gherkin. With `markdown = FALSE`, HTML pages show the block of Gherkin too.
#'
#' Scenarios are selected like in [test()]. By default only scenarios matching
#' `r format_option_default("cucumber.rd_tags")` are selected, so that you choose the ones
#' that make good documentation. Set the `cucumber.rd_tags` option to use another tag
#' expression, or pass `tags = NULL` to select scenarios without a tag.
#'
#' On a pkgdown site, code is highlighted by the site's theme.
#'
#' It turns on markdown for the roxygen block it's in.
#'
#' @param path Path to the directory containing the `.feature` files. Its subdirectories are
#'   searched too. Defaults to the `cucumber.path` option, see [opts].
#'   Relative paths are relative to the working directory, the package's root when you
#'   run `devtools::document()`.
#' @param filter If not NULL, only features with file names matching this regular expression
#'   are documented. Matching is performed on the file name after it's stripped of ".feature" or ".feature.md".
#' @param tags If not NULL, select scenarios by tag expression string, see [test()].
#'   Defaults to the `cucumber.rd_tags` option, see [opts].
#' @param name If not NULL, only scenarios with names matching any of these regular expressions
#'   are documented.
#' @param features If not NULL, only these feature files are documented. Relative paths are
#'   relative to `path`. A directory selects the feature files in it and its subdirectories.
#'   Add `:line` to select only the scenario at that line, e.g.
#'   `"addition.feature:12"`. The line of an example row selects only that example.
#' @param section Name of the section. Defaults to the `cucumber.rd_section` option, see [opts].
#' @param markdown If TRUE, HTML pages show each feature like Markdown with Gherkin. If
#'   FALSE, they show it as one block of Gherkin, as it's written, like the help page.
#' @param ... Additional arguments passed to `grepl()`.
#' @return Lines of roxygen tags, for `@eval`.
#'
#' @eval features_rd(features = "r-features_rd.feature")
#'
#' @export
#' @md
features_rd <- function(
  path = getOption("cucumber.path"),
  filter = NULL,
  tags = getOption("cucumber.rd_tags"),
  name = NULL,
  features = NULL,
  section = getOption("cucumber.rd_section"),
  markdown = TRUE,
  ...
) {
  checkmate::assert_string(section, min.chars = 1)
  checkmate::assert_flag(markdown)
  check_selection(path, filter, tags, name, features, ...)
  lines <- feature_lines(features, path)
  files <- select_features(path, filter, lines, ...)
  sources <- parse_features(files)
  rd <- unlist(map(files, \(file) {
    pickles <- filter_pickles(sources[[file]]$pickles, tags, name, lines[[file]])
    feature_rd(sources[[file]]$document, pickles, read_feature(file), file, markdown)
  }))
  if (length(rd) == 0) {
    abort_user(
      "No scenarios to document.",
      body = c(i = if (is.null(tags)) {
        "Select scenarios with `features`, `filter` or `name`."
      } else {
        paste0("Tag the scenarios with `", tags, "`, or select them whatever their tags with `tags = NULL`.")
      })
    )
  }
  c("@md", paste0("@section ", section, ":"), rd)
}

#' Rd of a feature with its selected scenarios: a block of Gherkin written as
#' in its source, and for HTML like Markdown with Gherkin or the same block
#'
#' @param pickles The selected pickles of the document
#' @param source The lines of the feature file
#' @param markdown Whether HTML shows it like Markdown with Gherkin
#' @return Lines of Rd, or NULL if no scenario is selected
#' @importFrom purrr map map_chr map_int
#' @keywords internal
#' @noRd
feature_rd <- function(document, pickles, source, file, markdown) {
  if (length(pickles) == 0) {
    return(NULL)
  }
  # The scenarios and the outline rows that are selected
  selected <- unlist(map(pickles, \(pickle) pickle$message$astNodeIds))
  feature <- document$feature
  feature$children <- prune_children(feature$children, selected)
  flavour <- gherkin_flavour(file)
  lines <- source_lines(document$feature, nodes(feature), source, flavour, selected)
  code <- flavour$block_code(c("", source)[lines + 1], feature$location$column)
  html <- if (markdown) {
    html <- node_rd(feature)
    # An empty block to start the HTML block of gherkin_rd()
    c("<pre hidden></pre >}}", "\\if{html}{", html, paste0("}", padding(html)))
  } else {
    pre <- gherkin_pre(code, lines, gherkin_tokens(document, source))
    paste0(pre, "}}", padding(pre))
  }
  c(gherkin_rd(code, html), paste0("Source: `", file, "`"), "")
}

#' The children that document the selection: the selected scenarios with
#' their selected Examples rows, the Rules with some, and the Background
#' beside them
#' @param selected The ids of the selected scenarios and Examples rows
#' @return The children, empty if none is selected
#' @importFrom purrr compact
#' @keywords internal
#' @noRd
prune_children <- function(children, selected) {
  kept <- compact(map(children, \(child) {
    if (!is.null(child$scenario) && child$scenario$id %in% selected) {
      child$scenario$examples <- compact(map(child$scenario$examples, \(examples) {
        examples$tableBody <- Filter(\(row) row$id %in% selected, examples$tableBody)
        if (length(examples$tableBody) > 0) examples
      }))
      child
    } else if (!is.null(child$rule)) {
      child$rule$children <- prune_children(child$rule$children, selected)
      if (length(child$rule$children) > 0) child
    }
  }))
  if (length(kept) == 0) {
    return(list())
  }
  c(Filter(\(child) !is.null(child$background), children), kept)
}

#' A node and the nodes of its children, as they're written
#' @keywords internal
#' @noRd
nodes <- function(node) {
  c(list(node), unlist(map(node$children, \(child) nodes(child_node(child))), recursive = FALSE))
}

child_node <- function(child) child$background %||% child$scenario %||% child$rule

#' The lines of the source of the nodes, each from its keyword to the next
#' child, without tags and unselected Examples rows, and a 0 for the blank
#' line between them
#' @param feature The feature of the document, with all its children
#' @param nodes The nodes to show
#' @keywords internal
#' @noRd
source_lines <- function(feature, nodes, source, flavour, selected) {
  all <- nodes(feature)
  starts <- c(map_int(all[-1], first_line), length(source) + 1)
  drop <- unlist(map(all, \(node) {
    map(node$examples, \(examples) {
      c(map_int(examples$tags, \(tag) tag$location$line), unselected_rows(examples, selected))
    })
  }))
  lines <- map(nodes, \(node) {
    from <- node$location$line
    lines <- setdiff(from:(min(starts[starts > from]) - 1), drop)
    # Without the blank lines and comments before the next child
    while (length(lines) > 0 && grepl(flavour$block_end, source[[lines[[length(lines)]]]])) {
      lines <- lines[-length(lines)]
    }
    lines
  })
  unlist(map(lines, \(x) c(0L, x)))[-1]
}

#' Rd of a node, like Markdown with Gherkin of `pretty()` of the Gherkin
#' utilities: a subsection with its description, a list of steps, tables,
#' Doc Strings as code, and the subsections of its Examples and children
#' @keywords internal
#' @noRd
node_rd <- function(node) {
  name <- if (nzchar(node$name)) paste0(": ", rd_text(node$name)) else ":"
  description <- if (nzchar(node$description %||% "")) rd_text(trimws(strsplit(node$description, "\n")[[1]]))
  steps <- unlist(map(node$steps, \(step) {
    c(
      paste0("\\item ", step$keyword, rd_text(step$text)),
      if (!is.null(step$dataTable)) table_rd(step$dataTable$rows),
      if (!is.null(step$docString)) doc_string_rd(step$docString)
    )
  }))
  c(
    paste0("\\subsection{", node$keyword, name, "}{"),
    description,
    if (length(steps) > 0) c("\\itemize{", steps, "}"),
    if (!is.null(node$tableHeader)) table_rd(c(list(node$tableHeader), node$tableBody)),
    unlist(map(node$examples, node_rd)),
    unlist(map(node$children, \(child) node_rd(child_node(child)))),
    "}"
  )
}

#' Rd of the rows of a table, the first one its header. A cell is on one
#' line, its new lines shown as in Gherkin
#' @keywords internal
#' @noRd
table_rd <- function(rows) {
  cells <- map(rows, \(row) map_chr(row$cells, \(cell) rd_text(gsub("\n", "\\n", cell$value, fixed = TRUE))))
  c(
    paste0("\\tabular{", strrep("l", length(cells[[1]])), "}{"),
    # Without a \cr after the last row, which would be an empty row
    paste(map_chr(cells, \(x) paste(x, collapse = " \\tab ")), collapse = " \\cr\n"),
    "}"
  )
}

#' Rd of a Doc String: highlighted Gherkin when it's Gherkin, else code
#' @keywords internal
#' @noRd
doc_string_rd <- function(doc_string) {
  content <- strsplit(doc_string$content, "\n")[[1]]
  content <- if (length(content) == 0) "" else content
  media_type <- doc_string$mediaType %||% ""
  document <- if (media_type %in% c("", "gherkin")) tryCatch(parse_gherkin(content), error = \(e) NULL)
  if (!is.null(document$feature) || media_type == "gherkin") {
    tokens <- gherkin_tokens(document %||% list(), content)
    return(paste0("\\out{", gherkin_pre(content, seq_along(content), tokens), "}"))
  }
  code <- rd_escape(content)
  code[[1]] <- paste0("\\preformatted{", code[[1]])
  code[[length(code)]] <- paste0(code[[length(code)]], "}")
  code
}

#' Rd of text: escaped, with its code spans as code
#' @keywords internal
#' @noRd
rd_text <- function(x) {
  map_chr(regmatches(x, gregexpr("`[^`]*`", x), invert = NA), \(pieces) {
    code <- seq_along(pieces) %% 2 == 0
    pieces[code] <- paste0("\\code{", rd_escape(substring(pieces[code], 2, nchar(pieces[code]) - 1)), "}")
    pieces[!code] <- rd_escape(pieces[!code])
    paste(pieces, collapse = "")
  })
}

rd_escape <- function(x) gsub("([{}%])", "\\\\\\1", gsub("\\", "\\\\", x, fixed = TRUE))

#' Spaces after the end of an \if: roxygen finds it in bytes, but cuts the
#' text in characters, so each extra byte of a character like £ takes one
#' more character after it, spaces and not the Rd that follows
#' @keywords internal
#' @noRd
padding <- function(x) strrep(" ", sum(nchar(x, "bytes") - nchar(x)))

#' Rd of a feature: the lines of Gherkin as they're written, and for HTML
#' its Rd
#' @param code The lines
#' @param html Lines of Rd for HTML, after an opening `\\if` and `\\out`: the
#'   first one starts with `<pre` and closes them
#' @keywords internal
#' @noRd
gherkin_rd <- function(code, html) {
  # Rd, not a markdown code block: pkgdown empties code blocks of a language
  # pandoc can't highlight, like gherkin, and highlights the others as R.
  # roxygen evaluates `r ` code of the markdown before it reads Rd, so a
  # ```r Doc String and the backticks of a description would make R code.
  # Markdown isn't read in an HTML block, from a line starting with <pre to
  # a line with </pre>: all of it is in one, ended by an Rd comment
  code <- rd_escape(code)
  code[[1]] <- paste0("\\if{text,latex}{\\preformatted{", code[[1]])
  c("\\if{html}{\\out{", html, code, "%</pre>", paste0("}}", padding(code)), "")
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

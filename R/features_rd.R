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
#' It adds a section, "Specification" by default, with each selected feature: its name, its
#' description, the Rules and Backgrounds of the selected scenarios and the scenarios, without
#' their tags. Of a Scenario Outline, only the selected Examples rows are shown.
#'
#' In the help page, each feature is one block of Gherkin, as it's written. On HTML pages,
#' like the pkgdown reference page, it's shown like Markdown with Gherkin: the names of the
#' feature and of its Rules, Backgrounds, scenarios and Examples are headers, steps are a
#' list, tables are tables and Doc Strings are code, a Doc String of Gherkin highlighted as
#' Gherkin. With `markdown = FALSE`, HTML pages show the block of Gherkin too.
#'
#' Scenarios are selected like in [test()]. By default only scenarios tagged `@rd` are
#' selected, so that you choose the ones that make good documentation. Set the
#' `cucumber.rd_tags` option to use another tag expression, or pass `tags = NULL` to select
#' scenarios without a tag.
#'
#' On a pkgdown site, code is highlighted by the site's theme.
#'
#' It turns on markdown for the roxygen block it's in.
#'
#' @param path Path to the directory containing the `.feature` files. Its subdirectories are
#'   searched too. Defaults to the `cucumber.path` option, or `"tests/acceptance"` if it's not set.
#'   Relative paths are relative to the working directory, the package's root when you
#'   run `devtools::document()`.
#' @param filter If not NULL, only features with file names matching this regular expression
#'   are documented. Matching is performed on the file name after it's stripped of ".feature" or ".feature.md".
#' @param tags If not NULL, select scenarios by tag expression string, see [test()].
#'   Defaults to the `cucumber.rd_tags` option, or `"@rd"` if it's not set.
#' @param name If not NULL, only scenarios with names matching any of these regular expressions
#'   are documented.
#' @param features If not NULL, only these feature files are documented. Relative paths are
#'   relative to `path`. A directory selects the feature files in it and its subdirectories.
#'   Add `:line` to select only the scenario at that line, e.g.
#'   `"addition.feature:12"`. The line of an example row selects only that example.
#' @param section Name of the section. Defaults to the `cucumber.rd_section` option, or
#'   `"Specification"` if it's not set.
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
  path = getOption("cucumber.path", "tests/acceptance"),
  filter = NULL,
  tags = getOption("cucumber.rd_tags", "@rd"),
  name = NULL,
  features = NULL,
  section = getOption("cucumber.rd_section", "Specification"),
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
  feature <- document$feature
  flavour <- gherkin_flavour(file)
  # The scenarios and the outline rows that are selected
  selected <- unlist(map(pickles, \(pickle) pickle$message$astNodeIds))
  tokens <- gherkin_tokens(document, source)
  # A child of the feature or of a rule ends before the first line of the next one
  children <- c(feature$children, unlist(map(feature$children, \(child) child$rule$children), recursive = FALSE))
  starts <- c(unlist(map(children, \(child) {
    node <- child$background %||% child$scenario %||% child$rule
    first_line(node)
  })), length(source) + 1)
  # The lines of a node, from its keyword to the next child, without its tags
  # and, of a Scenario Outline, without the Examples' tags and unselected rows
  node_lines <- function(node, level) {
    drop <- unlist(map(node$examples, \(examples) {
      c(map_int(examples$tags, \(tag) tag$location$line), unselected_rows(examples, selected))
    }))
    from <- node$location$line
    to <- min(starts[starts > from]) - 1
    lines <- setdiff(from:to, drop)
    # Without the blank lines and comments before the next child
    while (length(lines) > 0 && grepl(flavour$block_end, source[[lines[[length(lines)]]]])) {
      lines <- lines[-length(lines)]
    }
    lines
  }
  # A list of the parts of the children, made by `part` of a node and its
  # level: their Background and selected scenarios, and the Rules with selected
  # scenarios
  children_parts <- function(children, part, level = 1) {
    parts <- unlist(map(children, \(child) {
      if (!is.null(child$scenario) && child$scenario$id %in% selected) {
        list(part(child$scenario, level))
      } else if (!is.null(child$rule)) {
        rule_parts <- children_parts(child$rule$children, part, level + 1)
        if (length(rule_parts) > 0) c(list(part(child$rule, level)), rule_parts)
      }
    }), recursive = FALSE)
    if (length(parts) == 0) {
      return(NULL)
    }
    background <- Find(\(child) !is.null(child$background), children)$background
    c(if (!is.null(background)) list(part(background, level)), parts)
  }
  parts <- function(part) c(list(part(feature, 0)), children_parts(feature$children, part))
  # Line 0 is the blank line between parts
  lines <- unlist(map(parts(node_lines), \(part) c(0L, part)))[-1]
  code <- flavour$block_code(c("", source)[lines + 1], feature$location$column)
  html <- if (markdown) {
    html <- nest_subsections(parts(\(node, level) node_rd(node, level, selected)))
    # An empty block to start the HTML block of gherkin_rd()
    c("<pre hidden></pre >}}", "\\if{html}{", html, paste0("}", padding(html)))
  } else {
    pre <- gherkin_pre(code, lines, tokens)
    paste0(pre, "}}", padding(pre))
  }
  c(gherkin_rd(code, html), paste0("Source: `", file, "`"), "")
}

#' Rd of a node with its steps and selected Examples, like Markdown with
#' Gherkin of `pretty()` of the Gherkin utilities: a subsection, a list of
#' steps, tables, and Doc Strings as code
#' @param level 0 for the Feature, 1 for its Rules and children, 2 for the
#'   children of a Rule
#' @param selected The ids of the selected Examples rows
#' @return Lines of Rd, of a subsection left open, with its `level`
#' @keywords internal
#' @noRd
node_rd <- function(node, level, selected) {
  name <- if (nzchar(node$name)) paste0(": ", rd_text(node$name)) else ":"
  description <- if (nzchar(node$description %||% "")) rd_text(trimws(strsplit(node$description, "\n")[[1]]))
  steps <- unlist(map(node$steps, \(step) {
    c(
      paste0("\\item ", step$keyword, rd_text(step$text)),
      if (!is.null(step$dataTable)) table_rd(step$dataTable$rows),
      if (!is.null(step$docString)) doc_string_rd(step$docString)
    )
  }))
  examples <- unlist(map(node$examples, \(examples) {
    rows <- Filter(\(row) row$id %in% selected, examples$tableBody)
    if (length(rows) > 0) {
      c(node_rd(examples, level + 1, selected), table_rd(c(list(examples$tableHeader), rows)), "}")
    }
  }))
  structure(c(
    paste0("\\subsection{", node$keyword, name, "}{"),
    description,
    if (length(steps) > 0) c("\\itemize{", steps, "}"),
    examples
  ), level = level)
}

#' Rd of subsections left open, each closed before the next one of its level
#' or a lower one
#' @param parts Lines of Rd, with their `level`
#' @keywords internal
#' @noRd
nest_subsections <- function(parts) {
  open <- integer()
  rd <- character()
  for (part in parts) {
    level <- attr(part, "level")
    rd <- c(rd, rep("}", sum(open >= level)), part)
    open <- c(open[open < level], level)
  }
  c(rd, rep("}", length(open)))
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

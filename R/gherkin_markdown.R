# Markdown with Gherkin: a `.feature.md` file is Markdown whose headers are
# the Feature, Rule, Background, Scenario and Examples, whose list items
# starting with a step keyword are steps, and whose code blocks are Doc
# Strings. Any other Markdown is ignored. Its lines are classified by
# these token matchers instead of TOKEN_MATCHERS, ported from
# GherkinInMarkdownTokenMatcher.ts of the official parser, and parsed by the
# same state machine, see gherkin_flavours().

MARKDOWN_HEADER <- "^#{1,6}\\s"
MARKDOWN_BULLET <- "^\\s*[*+-]\\s*"
MARKDOWN_DOCSTRING_SEPARATOR <- "^(```[`]*)(.*)"

#' Match a Markdown title line: `prefix`, one of `keywords`, then `suffix`.
#' The token's indent includes the prefix.
#' @noRd
match_markdown_title <- function(p, token, prefix, keywords, suffix, type) {
  start <- regexpr(prefix, token$trimmed, perl = TRUE)
  if (start == -1) {
    return(NULL)
  }
  length <- attr(start, "match.length")
  rest <- substring(token$trimmed, length + 1L)
  steps <- GHERKIN_DIALECTS[[p$language]]$steps
  for (keyword in keywords) {
    if (startsWith(rest, paste0(keyword, suffix))) {
      return(matched(
        token,
        type,
        str_trim(substring(rest, nchar(keyword) + nchar(suffix) + 1L)),
        keyword,
        keyword_type = if (keyword %in% names(steps)) unname(steps[[keyword]]),
        indent = token$indent + length
      ))
    }
  }
  NULL
}

markdown_header <- function(type) {
  function(p, token) {
    match_markdown_title(p, token, MARKDOWN_HEADER, GHERKIN_DIALECTS[[p$language]]$titles[[type]], ":", type)
  }
}

#' Whether a table row is the separator between a Markdown table's header and
#' its body, like `| --- | :-: |`
#' @noRd
is_gfm_table_separator <- function(token) {
  cells <- vapply(table_cells(token$trimmed, token$indent), \(cell) cell$text, character(1))
  any(grepl("^:?-+:?$", cells))
}

MARKDOWN_TOKEN_MATCHERS <- list(
  EOF = function(p, token) matched(token, "EOF"),
  # An empty line, or any line that isn't Gherkin
  Empty = function(p, token) {
    gherkin <- c(
      "TagLine", "FeatureLine", "ScenarioLine", "BackgroundLine", "ExamplesLine", "RuleLine",
      "TableRow", "Comment", "Language", "DocStringSeparator", "StepLine"
    )
    # Tried in order until one matches, for empty lines too, as matching a
    # Feature or a Doc String separator changes the state of the parser
    other <- TRUE
    for (type in gherkin) {
      if (!is.null(MARKDOWN_TOKEN_MATCHERS[[type]](p, token))) {
        other <- FALSE
        break
      }
    }
    if (token$trimmed == "" || other) matched(token, "Empty")
  },
  # A Markdown table's separator row is a comment, but not one of the
  # document's comments
  Comment = function(p, token) {
    if (starts_with(token, "|") && is_gfm_table_separator(token)) matched(token, "GfmTableSeparator")
  },
  # Markdown has no `# language:` line, use the `cucumber.language` option
  Language = function(p, token) NULL,
  TagLine = function(p, token) {
    found <- gregexpr("`(@[^`]+)`", token$trimmed)[[1]]
    if (found[[1]] == -1) {
      return(NULL)
    }
    tags <- lapply(seq_along(found), \(i) {
      list(
        column = token$indent + found[[i]] + 1L,
        text = substring(token$trimmed, found[[i]] + 1L, found[[i]] + attr(found, "match.length")[[i]] - 2L)
      )
    })
    matched(token, "TagLine", items = tags)
  },
  # The first line that can be the Feature is: its header, or any line, so a
  # document doesn't have to start with it
  FeatureLine = function(p, token) {
    if (isTRUE(p$matched_feature_line)) {
      return(NULL)
    }
    p$matched_feature_line <- TRUE
    markdown_header("FeatureLine")(p, token) %||% matched(token, "FeatureLine", token$trimmed)
  },
  RuleLine = markdown_header("RuleLine"),
  BackgroundLine = markdown_header("BackgroundLine"),
  ScenarioLine = markdown_header("ScenarioLine"),
  ExamplesLine = markdown_header("ExamplesLine"),
  StepLine = function(p, token) {
    keywords <- setdiff(names(GHERKIN_DIALECTS[[p$language]]$steps), "* ")
    match_markdown_title(p, token, MARKDOWN_BULLET, keywords, "", "StepLine")
  },
  # Gherkin tables are indented 2 to 5 spaces, to tell them from Markdown tables
  TableRow = function(p, token) {
    if (grepl("^\\s\\s\\s?\\s?\\s?\\|", token$text, perl = TRUE) && !is_gfm_table_separator(token)) {
      matched(token, "TableRow", items = table_cells(token$trimmed, token$indent))
    }
  },
  # A code block is a Doc String, closed only by the fence that opened it.
  # Its lines lose the indent of the opening fence, and so do the lines
  # after it.
  DocStringSeparator = function(p, token) {
    pattern <- if (is.null(p$docstring_separator)) {
      MARKDOWN_DOCSTRING_SEPARATOR
    } else {
      paste0("^(", p$docstring_separator, ")$")
    }
    match <- regmatches(token$trimmed, regexec(pattern, token$trimmed, perl = TRUE))[[1]]
    if (length(match) == 0) {
      return(NULL)
    }
    separator <- match[[2]]
    if (is.null(p$docstring_separator)) {
      p$docstring_separator <- separator
      p$indent_to_remove <- token$indent
    } else {
      p$docstring_separator <- NULL
    }
    matched(token, "DocStringSeparator", if (length(match) > 2) match[[3]] else "", separator)
  },
  Other = function(p, token) {
    text <- if (p$indent_to_remove > token$indent) {
      token$trimmed
    } else {
      substring(token$text, p$indent_to_remove + 1L)
    }
    matched(token, "Other", text, indent = 0L)
  }
)

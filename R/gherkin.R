#' Parse a Gherkin document
#'
#' A port of the official Gherkin parser (https://github.com/cucumber/gherkin).
#' Each line is classified by its keyword, not by its indentation, and the
#' parser's state machine (R/gherkin_states.R) decides which lines may follow.
#' Like the official parser, it collects every syntax error with its
#' `(line:column)` and fails after reading the whole document.
#'
#' @param lines Lines of a feature file.
#' @param uri Path of the feature file, used in error messages.
#' @return A list with the `feature`, or a NULL `feature` for an empty document.
#' @keywords internal
#' @noRd
parse_gherkin <- function(lines, uri = NULL) {
  p <- new.env(parent = emptyenv())
  p$lines <- lines
  p$uri <- uri
  p$next_line <- 1L
  p$queue <- list()
  p$docstring_separator <- NULL
  p$indent_to_remove <- 0L
  p$dialect <- GHERKIN_DIALECTS$en
  p$errors <- character()
  p$stack <- list(new_ast_node("None"))

  start_rule(p, "GherkinDocument")
  state <- 0L
  repeat {
    token <- read_token(p)
    state <- match_token_at(p, state, token)
    if (token$is_eof) break
  }
  end_rule(p)

  if (length(p$errors) > 0) {
    abort_gherkin(p)
  }
  get_single(p$stack[[1]], "GherkinDocument")
}

# GHERKIN_DIALECTS in R/sysdata.rda has the keywords of every language from the
# official gherkin-languages.json, see update_gherkin(). Step keywords include
# the space that has to follow them. `*` is a keyword of every step type, so
# its type is unknown.

LANGUAGE_PATTERN <- "^\\s*#\\s*language\\s*:\\s*([a-zA-Z\\-_]+)\\s*$"

#' @importFrom stringr str_remove
read_token <- function(p) {
  if (length(p$queue) > 0) {
    token <- p$queue[[1]]
    p$queue <- p$queue[-1]
    return(token)
  }
  i <- p$next_line
  p$next_line <- i + 1L
  if (i > length(p$lines)) {
    return(list(line = i, is_eof = TRUE))
  }
  text <- p$lines[[i]]
  trimmed <- str_remove(text, "^\\s+")
  list(
    line = i,
    is_eof = FALSE,
    text = text,
    trimmed = trimmed,
    indent = nchar(text) - nchar(trimmed)
  )
}

match_token_at <- function(p, state, token) {
  spec <- GHERKIN_STATES[[as.character(state)]]
  for (transition in spec$transitions) {
    matched <- match_token(p, transition[[1]], token)
    if (is.null(matched)) {
      next
    }
    if (!is.na(transition[[2]]) && !lookahead(p, transition[[2]])) {
      next
    }
    for (action in transition[[3]]) {
      if (action == "build") {
        build(p, matched)
      } else if (action == "end") {
        end_rule(p)
      } else {
        start_rule(p, sub("^start:", "", action))
      }
    }
    return(transition[[4]])
  }
  add_error(p, unexpected_token_message(token, spec$expected))
  state
}

#' A tag line is ambiguous: it can tag the next scenario (lookahead 0) or the
#' next examples (lookahead 1), so the parser reads past tags, comments and
#' empty lines to see which keyword they belong to.
#' @noRd
lookahead <- function(p, n) {
  target <- c("ScenarioLine", "ExamplesLine")[[n + 1]]
  queue <- list()
  found <- FALSE
  repeat {
    token <- read_token(p)
    queue <- c(queue, list(token))
    if (!is.null(match_token(p, target, token))) {
      found <- TRUE
      break
    }
    skippable <- !is.null(match_token(p, "Empty", token)) ||
      !is.null(match_token(p, "Comment", token)) ||
      !is.null(match_token(p, "TagLine", token))
    if (!skippable) break
  }
  p$queue <- c(p$queue, queue)
  found
}

# Token matching ----------------------------------------------------------

#' Return the token classified as `type`, or NULL if it isn't one
#' @noRd
match_token <- function(p, type, token) {
  if (token$is_eof != (type == "EOF")) {
    return(NULL)
  }
  catch_gherkin_error(p, TOKEN_MATCHERS[[type]](p, token))
}

matched <- function(
  token,
  type,
  text = NULL,
  keyword = NULL,
  keyword_type = NULL,
  items = character(),
  indent = token$indent %||% 0L
) {
  token$type <- type
  token$matched_text <- text
  token$keyword <- keyword
  token$keyword_type <- keyword_type
  token$items <- items
  token$column <- indent + 1L
  token
}

starts_with <- function(token, prefix) {
  startsWith(token$trimmed, prefix)
}

#' @importFrom stringr str_trim
rest_trimmed <- function(token, n) {
  str_trim(substring(token$trimmed, n + 1L))
}

match_title_line <- function(p, token, type) {
  for (keyword in p$dialect$titles[[type]]) {
    if (starts_with(token, paste0(keyword, ":"))) {
      return(matched(token, type, rest_trimmed(token, nchar(keyword) + 1L), keyword))
    }
  }
  NULL
}

#' @importFrom stringr str_match
TOKEN_MATCHERS <- list(
  EOF = function(p, token) matched(token, "EOF"),
  Empty = function(p, token) {
    if (token$trimmed == "") matched(token, "Empty", indent = 0L)
  },
  Comment = function(p, token) {
    if (starts_with(token, "#")) matched(token, "Comment", token$text, indent = 0L)
  },
  Language = function(p, token) {
    language <- str_match(token$trimmed, LANGUAGE_PATTERN)[, 2]
    if (is.na(language)) {
      return(NULL)
    }
    if (is.null(GHERKIN_DIALECTS[[language]])) {
      gherkin_error(paste0("Language not supported: ", language), token$line, token$indent + 1L)
    }
    p$dialect <- GHERKIN_DIALECTS[[language]]
    matched(token, "Language", language)
  },
  TagLine = function(p, token) {
    if (starts_with(token, "@")) matched(token, "TagLine", items = tag_items(token))
  },
  FeatureLine = function(p, token) match_title_line(p, token, "FeatureLine"),
  RuleLine = function(p, token) match_title_line(p, token, "RuleLine"),
  BackgroundLine = function(p, token) match_title_line(p, token, "BackgroundLine"),
  ScenarioLine = function(p, token) match_title_line(p, token, "ScenarioLine"),
  ExamplesLine = function(p, token) match_title_line(p, token, "ExamplesLine"),
  StepLine = function(p, token) {
    steps <- p$dialect$steps
    for (keyword in names(steps)) {
      if (starts_with(token, keyword)) {
        return(matched(
          token,
          "StepLine",
          rest_trimmed(token, nchar(keyword)),
          keyword,
          keyword_type = steps[[keyword]]
        ))
      }
    }
    NULL
  },
  TableRow = function(p, token) {
    if (starts_with(token, "|")) matched(token, "TableRow", items = table_cells(token$trimmed))
  },
  DocStringSeparator = function(p, token) {
    # A Doc String is closed only by the separator that opened it
    for (separator in p$docstring_separator %||% c('"""', "```")) {
      if (starts_with(token, separator)) {
        media_type <- NULL
        if (is.null(p$docstring_separator)) {
          media_type <- rest_trimmed(token, nchar(separator))
          p$docstring_separator <- separator
          p$indent_to_remove <- token$indent
        } else {
          p$docstring_separator <- NULL
          p$indent_to_remove <- 0L
        }
        return(matched(token, "DocStringSeparator", media_type, separator))
      }
    }
    NULL
  },
  Other = function(p, token) {
    # Doc String lines lose the indent of the opening separator
    text <- if (p$indent_to_remove > token$indent) {
      token$trimmed
    } else {
      substring(token$text, p$indent_to_remove + 1L)
    }
    separator <- p$docstring_separator
    if (!is.null(separator)) {
      escaped <- paste0("\\", strsplit(separator, "")[[1]], collapse = "")
      text <- sub(escaped, separator, text, fixed = TRUE)
    }
    matched(token, "Other", text, indent = 0L)
  }
)

#' @importFrom stringr str_trim str_detect
tag_items <- function(token) {
  uncommented <- strsplit(token$trimmed, "\\s#", perl = TRUE)[[1]][[1]]
  column <- token$indent + 1L
  tags <- character()
  for (item in strsplit(uncommented, "@", fixed = TRUE)[[1]]) {
    tag <- str_trim(item, side = "right")
    if (tag == "") {
      next
    }
    if (str_detect(tag, "\\s")) {
      gherkin_error("A tag may not contain whitespace", token$line, column)
    }
    tags <- c(tags, paste0("@", tag))
    column <- column + nchar(item) + 1L
  }
  tags
}

#' Split a table row into cells. Text before the first and after the last `|`
#' is not a cell. `\|`, `\\` and `\n` are unescaped.
#' @importFrom stringr str_remove_all
#' @noRd
table_cells <- function(row) {
  chars <- strsplit(row, "")[[1]]
  cells <- character()
  cell <- ""
  first <- TRUE
  i <- 1L
  while (i <= length(chars)) {
    chr <- chars[[i]]
    i <- i + 1L
    if (chr == "|") {
      if (first) {
        first <- FALSE
      } else {
        # Cells keep their newlines
        cells <- c(cells, str_remove_all(cell, "^[ \\t\\x0B\\f\\r\\u0085\\u00A0]+|[ \\t\\x0B\\f\\r\\u0085\\u00A0]+$"))
      }
      cell <- ""
    } else if (chr == "\\") {
      chr <- if (i <= length(chars)) chars[[i]] else ""
      i <- i + 1L
      if (chr == "n") {
        cell <- paste0(cell, "\n")
      } else {
        if (!chr %in% c("|", "\\")) {
          cell <- paste0(cell, "\\")
        }
        cell <- paste0(cell, chr)
      }
    } else {
      cell <- paste0(cell, chr)
    }
  }
  cells
}

# AST building ------------------------------------------------------------

new_ast_node <- function(rule) {
  list(rule = rule, items = list())
}

get_items <- function(node, type) {
  node$items[[type]] %||% list()
}

get_single <- function(node, type) {
  items <- get_items(node, type)
  if (length(items) > 0) items[[1]]
}

ast_add <- function(p, type, item) {
  n <- length(p$stack)
  p$stack[[n]]$items[[type]] <- c(p$stack[[n]]$items[[type]], list(item))
}

start_rule <- function(p, rule) {
  p$stack <- c(p$stack, list(new_ast_node(rule)))
}

end_rule <- function(p) {
  n <- length(p$stack)
  node <- p$stack[[n]]
  p$stack <- p$stack[-n]
  catch_gherkin_error(p, ast_add(p, node$rule, transform_node(node)))
}

build <- function(p, token) {
  if (token$type != "Comment") {
    ast_add(p, token$type, token)
  }
}

#' @importFrom purrr map
transform_node <- function(node) {
  switch(
    node$rule,
    Step = {
      line <- get_single(node, "StepLine")
      list(
        keyword = line$keyword,
        keyword_type = line$keyword_type,
        text = line$matched_text,
        line = line$line,
        data_table = get_single(node, "DataTable"),
        docstring = get_single(node, "DocString")
      )
    },
    DocString = {
      separator <- get_single(node, "DocStringSeparator")
      list(
        content = vapply(get_items(node, "Other"), \(token) token$matched_text, character(1)),
        media_type = if (nzchar(separator$matched_text)) separator$matched_text,
        line = separator$line
      )
    },
    DataTable = {
      rows <- table_rows(node)
      list(rows = rows, line = rows[[1]]$line)
    },
    ExamplesTable = table_rows(node),
    Background = list(steps = get_items(node, "Step")),
    ScenarioDefinition = {
      scenario <- get_single(node, "Scenario")
      line <- get_single(scenario, "ScenarioLine")
      list(
        tags = node_tags(node),
        keyword = line$keyword,
        name = line$matched_text,
        line = line$line,
        steps = get_items(scenario, "Step"),
        examples = get_items(scenario, "ExamplesDefinition")
      )
    },
    ExamplesDefinition = {
      table <- get_single(get_single(node, "Examples"), "ExamplesTable")
      list(
        tags = node_tags(node),
        header = if (length(table) > 0) table[[1]],
        body = table[-1]
      )
    },
    Feature = {
      header <- get_single(node, "FeatureHeader")
      line <- get_single(header, "FeatureLine")
      if (is.null(line)) {
        return(NULL)
      }
      list(
        tags = node_tags(header),
        keyword = line$keyword,
        name = line$matched_text,
        background = get_single(node, "Background"),
        scenarios = get_items(node, "ScenarioDefinition"),
        rules = get_items(node, "Rule")
      )
    },
    Rule = {
      header <- get_single(node, "RuleHeader")
      line <- get_single(header, "RuleLine")
      if (is.null(line)) {
        return(NULL)
      }
      list(
        tags = node_tags(header),
        name = line$matched_text,
        background = get_single(node, "Background"),
        scenarios = get_items(node, "ScenarioDefinition")
      )
    },
    GherkinDocument = list(feature = get_single(node, "Feature")),
    node
  )
}

node_tags <- function(node) {
  tags <- get_items(get_single(node, "Tags"), "TagLine") |>
    map(\(token) token$items)
  as.character(unlist(tags))
}

table_rows <- function(node) {
  rows <- get_items(node, "TableRow") |>
    map(\(token) list(line = token$line, column = token$column, cells = token$items))
  for (row in rows) {
    if (length(row$cells) != length(rows[[1]]$cells)) {
      gherkin_error("inconsistent cell count within the table", row$line, row$column)
    }
  }
  rows
}

# Errors ------------------------------------------------------------------

gherkin_error <- function(message, line, column) {
  abort(sprintf("(%d:%d): %s", line, column, message), class = "gherkin_error")
}

catch_gherkin_error <- function(p, expr) {
  tryCatch(expr, gherkin_error = function(e) {
    add_error(p, conditionMessage(e))
    NULL
  })
}

#' @importFrom stringr str_trim
unexpected_token_message <- function(token, expected) {
  expected <- paste(expected, collapse = ", ")
  if (token$is_eof) {
    sprintf("(%d:0): unexpected end of file, expected: %s", token$line, expected)
  } else {
    sprintf("(%d:%d): expected: %s, got '%s'", token$line, token$indent + 1L, expected, str_trim(token$trimmed))
  }
}

add_error <- function(p, message) {
  if (message %in% p$errors) {
    return()
  }
  p$errors <- c(p$errors, message)
  # Like the official parser, give up after 10 errors
  if (length(p$errors) > 10) {
    abort_gherkin(p)
  }
}

#' @importFrom rlang abort
#' @importFrom purrr set_names
abort_gherkin <- function(p) {
  abort(
    paste("Can't parse", p$uri %||% "feature"),
    body = set_names(p$errors, rep("x", length(p$errors))),
    class = "cucumber_parse_error",
    errors = p$errors,
    trace = empty_trace(),
    call = NULL
  )
}

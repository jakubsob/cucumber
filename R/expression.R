# Cucumber Expressions and Regular Expressions, ported from
# github.com/cucumber/cucumber-expressions (javascript/src):
# CucumberExpressionTokenizer, CucumberExpressionParser, CucumberExpression,
# RegularExpression, TreeRegexp and CucumberExpressionGenerator.

#' Convert a step definition's expression to a regular expression
#'
#' A description that starts with `^`, ends with `$` or is surrounded by `/`
#' is a regular expression, as in cucumber-jvm. Anything else is a Cucumber
#' Expression.
#'
#' @return A regular expression with two attributes: `parameters`, the
#'   parameter type of each top-level capture group, and `groups`, the number
#'   of the capture group each capture group is nested in (0 at the top level).
#' @keywords internal
#' @noRd
expression_to_pattern <- function(x, parameters = get_parameters()) {
  if (is_regular_expression(x)) {
    pattern <- if (grepl("^/.*/$", x)) substr(x, 2, nchar(x) - 1) else x
    check_regex(pattern)
    groups <- regex_groups(pattern)
    types <- lapply(
      groups$source[groups$parent == 0],
      \(source) parameter_for_regexp(source, pattern, parameters)
    )
  } else {
    pattern <- cucumber_expression_to_regex(x, parameters)
    types <- attr(pattern, "parameters")
    groups <- regex_groups(pattern)
  }
  structure(c(pattern), parameters = types, groups = groups$parent)
}

#' The arguments of a text that a pattern of `expression_to_pattern()`
#' matches: each top-level capture group, transformed by its parameter type. A
#' parameter type's regexp with capture groups of its own passes their text to
#' its transformer.
#' @keywords internal
#' @noRd
#' @importFrom stringr str_match
pattern_arguments <- function(text, pattern) {
  values <- unname(str_match(text, pattern)[1, -1])
  groups <- attr(pattern, "groups")
  # Map, as purrr would wrap a transformer's error
  Map(
    \(group, parameter) {
      children <- which(groups == group)
      transform_parameter(parameter, values[group], values[if (length(children)) children else group])
    },
    which(groups == 0),
    attr(pattern, "parameters")
  )
}

is_regular_expression <- function(x) {
  startsWith(x, "^") || endsWith(x, "$") || grepl("^/.*/$", x)
}

#' Fail on an invalid regular expression before any step is matched with it
#' @keywords internal
#' @noRd
#' @importFrom stringr str_detect
check_regex <- function(pattern) {
  tryCatch(
    str_detect("", pattern),
    error = function(e) {
      abort(
        paste0("This Regular Expression has a problem:\n\n", pattern, "\n\n", conditionMessage(e)),
        class = "cucumber_expression_error",
        call = NULL,
        trace = empty_trace()
      )
    }
  )
  invisible(pattern)
}

#' The capture groups of a regular expression, in order
#'
#' @return A list with the `parent` capture group of each capture group
#'   (0 at the top level) and its `source`.
#' @keywords internal
#' @noRd
regex_groups <- function(pattern) {
  chars <- strsplit(pattern, "")[[1]]
  parent <- integer()
  source <- character()
  # Open groups. `scope` is the capture group that a group nested inside
  # belongs to: the group itself, or its parent for a non-capturing group.
  stack <- list()
  escaping <- FALSE
  char_class <- FALSE
  class_start <- 0L
  for (i in seq_along(chars)) {
    char <- chars[[i]]
    if (!escaping && !char_class && char == "[") {
      char_class <- TRUE
      class_start <- i
    } else if (!escaping && char == "]") {
      # A ] right after [ or [^ is a literal, like in []a] or [^]a]
      first <- i == class_start + 1 || (i == class_start + 2 && chars[[class_start + 1]] == "^")
      char_class <- char_class && first
    } else if (!escaping && !char_class && char == "(") {
      scope <- if (length(stack)) stack[[length(stack)]]$scope else 0L
      # (X) and (?<name>X) capture, (?:X), (?=X), (?<=X), (?<!X) etc. don't
      capturing <- !identical(chars[i + 1], "?") ||
        (identical(chars[i + 2], "<") && !chars[i + 3] %in% c("=", "!"))
      number <- NA_integer_
      if (capturing) {
        parent <- c(parent, scope)
        number <- length(parent)
        scope <- number
      }
      stack <- c(stack, list(list(number = number, scope = scope, start = i)))
    } else if (!escaping && !char_class && char == ")") {
      group <- stack[[length(stack)]]
      stack <- stack[-length(stack)]
      if (!is.na(group$number)) {
        source[group$number] <- substr(pattern, group$start + 1, i - 1)
      }
    }
    escaping <- char == "\\" && !escaping
  }
  list(parent = parent, source = source)
}

#' Find the parameter type of a regular expression's capture group
#'
#' A group whose regexp isn't a parameter type's regexp passes its text as is.
#'
#' @keywords internal
#' @noRd
parameter_for_regexp <- function(source, pattern, parameters) {
  candidates <- Filter(\(p) source %in% p$regexp, c(parameters, list(ANONYMOUS)))
  preferred <- Filter(\(p) p$prefer_for_regexp_match, candidates)
  if (length(candidates) > 1 && length(preferred) == 0) {
    names <- vapply(candidates, \(p) paste0("{", p$name, "}"), character(1))
    abort(
      paste0(
        "Your Regular Expression ", pattern, "\n",
        "matches multiple parameter types with regexp ", source, ":\n",
        "   ", paste(names, collapse = "\n   "), "\n\n",
        "I couldn't decide which one to use. ",
        "Use a Cucumber Expression instead of a Regular Expression, ",
        "or make one of the parameter types preferential ",
        "with `prefer_for_regexp_match = TRUE`."
      ),
      call = NULL,
      trace = empty_trace()
    )
  }
  if (length(preferred)) return(preferred[[1]])
  if (length(candidates)) return(candidates[[1]])
  # A group of no parameter type gets an unnamed one, as `{}` does, so its
  # step match argument in Cucumber Messages has no parameterTypeName
  .parameter("", source, \(x, ...) x)
}

#' Raise a Cucumber Expression error pointing at the problem
#'
#' `start` and `end` are 0-based columns, as in the official messages.
#' A solution suggesting an escape, like `'\/'`, gets a line showing how to
#' write it in an R string, as the official message shows expression syntax.
#'
#' @keywords internal
#' @noRd
expression_error <- function(expression, start, end, problem, solution, class = NULL, ...) {
  pointer <- paste0(strrep(" ", start), "^")
  if (end - start > 1) {
    pointer <- paste0(pointer, strrep("-", end - start - 2), "^")
  }
  escape <- regmatches(solution, regexpr("(?<=use ')\\\\[^']*(?=')", solution, perl = TRUE))
  if (length(escape)) {
    solution <- paste0(
      solution, "\n",
      "In an R string, double each backslash: \"", gsub("\\", "\\\\", escape, fixed = TRUE), "\"."
    )
  }
  abort(
    paste0(
      "This Cucumber Expression has a problem at column ", start + 1, ":\n\n",
      expression, "\n",
      pointer, "\n",
      problem, ".\n",
      solution
    ),
    class = c(class, "cucumber_expression_error"),
    ...,
    call = NULL,
    trace = empty_trace()
  )
}

#' Split a Cucumber Expression into tokens
#'
#' Runs of text and of whitespace are one token each. An escaped character is
#' text, so it can't be syntax or an alternation boundary.
#'
#' @keywords internal
#' @noRd
#' @importFrom stringr str_detect
tokenize_expression <- function(expression) {
  type_of <- function(char) {
    if (str_detect(char, "\\s")) return("white_space")
    switch(
      char,
      "/" = "alternation",
      "{" = "begin_parameter",
      "}" = "end_parameter",
      "(" = "begin_optional",
      ")" = "end_optional",
      "text"
    )
  }

  chars <- strsplit(expression, "")[[1]]
  tokens <- list(list(type = "start_of_line", text = "", start = 0, end = 0))
  buffer <- character()
  buffer_start <- 0
  escaped <- 0
  previous <- "start_of_line"
  treat_as_text <- FALSE

  flush <- function() {
    # A text token spans the backslashes escaping its characters too
    end <- buffer_start + length(buffer)
    if (previous == "text") {
      end <- end + escaped
      escaped <<- 0
    }
    token <- list(
      type = previous,
      text = paste(buffer, collapse = ""),
      start = buffer_start,
      end = end
    )
    buffer <<- character()
    buffer_start <<- end
    token
  }

  for (i in seq_along(chars)) {
    char <- chars[[i]]
    if (!treat_as_text && char == "\\") {
      escaped <- escaped + 1
      treat_as_text <- TRUE
      next
    }
    type <- type_of(char)
    if (treat_as_text) {
      if (type == "text" && char != "\\") {
        expression_error(
          expression, i - 1, i,
          "Only the characters '{', '}', '(', ')', '\\', '/' and whitespace can be escaped",
          "If you did mean to use an '\\' you can use '\\\\' to escape it"
        )
      }
      type <- "text"
    }
    treat_as_text <- FALSE
    if (type != previous || !type %in% c("white_space", "text")) {
      token <- flush()
      if (token$type != "start_of_line") tokens <- c(tokens, list(token))
    }
    buffer <- c(buffer, char)
    previous <- type
  }
  if (length(buffer)) tokens <- c(tokens, list(flush()))
  if (treat_as_text) {
    expression_error(
      expression, length(chars) - 1, length(chars),
      "The end of line can not be escaped",
      "You can use '\\\\' to escape the '\\'"
    )
  }
  c(
    tokens,
    list(list(type = "end_of_line", text = "", start = length(chars), end = length(chars)))
  )
}

# Parse a Cucumber Expression into a syntax tree
#
# ```
# cucumber-expression := ( alternation | optional | parameter | text )*
# alternation := (?<=left-boundary) + alternative* + ( '/' + alternative* )+ + (?=right-boundary)
# left-boundary := whitespace | } | ^
# right-boundary := whitespace | { | $
# alternative := optional | parameter | text
# optional := '(' + option* + ')'
# option := optional | parameter | text
# parameter := '{' + name* + '}'
# name := whitespace | .
# text := whitespace | ')' | '}' | .
# ```
#
# Each parser takes the index of the token to start at and returns how many
# tokens it consumed and the nodes it made.
#
parse_expression <- function(expression) {
  tokens <- tokenize_expression(expression)
  none <- list(consumed = 0, ast = list())
  node <- function(type, nodes = list(), text = NULL, start, end) {
    list(type = type, nodes = nodes, text = text, start = start, end = end)
  }
  looking_at <- function(at, types) {
    type <- if (at < 1) {
      "start_of_line"
    } else if (at > length(tokens)) {
      "end_of_line"
    } else {
      tokens[[at]]$type
    }
    type %in% types
  }

  parse_tokens_until <- function(parsers, start_at, end_types) {
    current <- start_at
    ast <- list()
    while (current <= length(tokens) && !looking_at(current, end_types)) {
      result <- NULL
      for (parser in parsers) {
        result <- parser(current)
        if (result$consumed > 0) break
      }
      if (result$consumed == 0) stop("No eligible parsers")
      current <- current + result$consumed
      ast <- c(ast, result$ast)
    }
    list(consumed = current - start_at, ast = ast)
  }

  parse_between <- function(type, begin, end, parsers) {
    function(current) {
      if (!looking_at(current, begin)) return(none)
      result <- parse_tokens_until(parsers(), current + 1, c(end, "end_of_line"))
      sub_current <- current + 1 + result$consumed
      begin_token <- tokens[[current]]
      if (!looking_at(sub_current, end)) {
        symbols <- c(begin_optional = "(", begin_parameter = "{")
        purpose <- c(begin_optional = "optional text", begin_parameter = "a parameter")
        end_symbols <- c(begin_optional = ")", begin_parameter = "}")
        expression_error(
          expression, begin_token$start, begin_token$end,
          paste0(
            "The '", symbols[[begin]], "' does not have a matching '",
            end_symbols[[begin]], "'"
          ),
          paste0(
            "If you did not intend to use ", purpose[[begin]],
            " you can use '\\", symbols[[begin]], "' to escape the ",
            purpose[[begin]]
          )
        )
      }
      list(
        consumed = sub_current + 1 - current,
        ast = list(node(
          type,
          result$ast,
          start = begin_token$start,
          end = tokens[[sub_current]]$end
        ))
      )
    }
  }

  parse_text <- function(current) {
    token <- tokens[[current]]
    if (token$type %in% c("white_space", "text", "end_parameter", "end_optional")) {
      return(list(
        consumed = 1,
        ast = list(node("text", text = token$text, start = token$start, end = token$end))
      ))
    }
    if (token$type == "alternation") {
      expression_error(
        expression, token$start, token$end,
        "An alternation can not be used inside an optional",
        paste(
          "If you did not mean to use an alternation you can use '\\/' to escape the '/'.",
          "Otherwise rephrase your expression or consider using a regular expression instead."
        )
      )
    }
    none
  }

  parse_name <- function(current) {
    token <- tokens[[current]]
    if (token$type %in% c("white_space", "text")) {
      return(list(
        consumed = 1,
        ast = list(node("text", text = token$text, start = token$start, end = token$end))
      ))
    }
    if (token$type %in% c("begin_parameter", "end_parameter", "begin_optional", "end_optional", "alternation")) {
      expression_error(
        expression, token$start, token$end,
        "Parameter names may not contain '{', '}', '(', ')', '\\' or '/'",
        "Did you mean to use a regular expression?"
      )
    }
    none
  }

  parse_parameter <- parse_between(
    "parameter", "begin_parameter", "end_parameter",
    \() list(parse_name)
  )
  parse_optional <- parse_between(
    "optional", "begin_optional", "end_optional",
    \() list(parse_optional, parse_parameter, parse_text)
  )

  parse_alternative_separator <- function(current) {
    if (!looking_at(current, "alternation")) return(none)
    token <- tokens[[current]]
    list(
      consumed = 1,
      ast = list(node("alternative", text = token$text, start = token$start, end = token$end))
    )
  }

  parse_alternation <- function(current) {
    if (!looking_at(current - 1, c("start_of_line", "white_space", "end_parameter"))) {
      return(none)
    }
    result <- parse_tokens_until(
      list(parse_alternative_separator, parse_optional, parse_parameter, parse_text),
      current,
      c("white_space", "end_of_line", "begin_parameter")
    )
    is_separator <- vapply(result$ast, \(n) n$type == "alternative", logical(1))
    if (!any(is_separator)) return(none)
    start <- tokens[[current]]$start
    # The right boundary token isn't consumed
    end <- tokens[[current + result$consumed]]$start
    separators <- result$ast[is_separator]
    alternative_of <- cumsum(is_separator)
    alternatives <- lapply(seq_len(length(separators) + 1), \(i) {
      node(
        "alternative",
        result$ast[!is_separator & alternative_of == i - 1],
        start = if (i == 1) start else separators[[i - 1]]$end,
        end = if (i > length(separators)) end else separators[[i]]$start
      )
    })
    list(
      consumed = result$consumed,
      ast = list(node("alternation", alternatives, start = start, end = end))
    )
  }

  parse_expression <- parse_between(
    "expression", "start_of_line", "end_of_line",
    \() list(parse_alternation, parse_optional, parse_parameter, parse_text)
  )
  parse_expression(1)$ast[[1]]
}

#' Escape text to match it literally in a regular expression
#' @keywords internal
#' @noRd
#' @importFrom stringr str_replace_all
escape_regex <- function(text) {
  str_replace_all(text, "([\\\\^\\[({$.|?*+})\\]])", "\\\\\\1")
}

#' Rewrite a Cucumber Expression as a regular expression
#'
#' @return An anchored regular expression with the parameter type of each
#'   parameter in the `parameters` attribute.
#' @keywords internal
#' @noRd
#' @importFrom stringr str_replace_all
cucumber_expression_to_regex <- function(expression, parameters) {
  used <- list()
  types_of <- function(node) vapply(node$nodes, \(n) n$type, character(1))
  fail <- function(node, problem, solution, ...) {
    expression_error(expression, node$start, node$end, problem, solution, ...)
  }
  rewrite_all <- function(nodes, collapse = "") {
    paste(vapply(nodes, rewrite, character(1)), collapse = collapse)
  }

  rewrite <- function(node) {
    switch(
      node$type,
      text = escape_regex(node$text),
      optional = {
        types <- types_of(node)
        if (any(types == "parameter")) {
          fail(
            node$nodes[[which(types == "parameter")[1]]],
            "An optional may not contain a parameter type",
            "If you did not mean to use an parameter type you can use '\\{' to escape the '{'"
          )
        }
        if (any(types == "optional")) {
          fail(
            node$nodes[[which(types == "optional")[1]]],
            "An optional may not contain an other optional",
            paste(
              "If you did not mean to use an optional type you can use '\\(' to escape the '('.",
              "For more complicated expressions consider using a regular expression instead."
            )
          )
        }
        if (!any(types == "text")) {
          fail(
            node,
            "An optional must contain some text",
            "If you did not mean to use an optional you can use '\\(' to escape the '('"
          )
        }
        paste0("(?:", rewrite_all(node$nodes), ")?")
      },
      alternation = {
        for (alternative in node$nodes) {
          if (length(alternative$nodes) == 0) {
            fail(
              alternative,
              "Alternative may not be empty",
              "If you did not mean to use an alternative you can use '\\/' to escape the '/'"
            )
          }
          if (!any(types_of(alternative) == "text")) {
            fail(
              alternative,
              "An alternative may not exclusively contain optionals",
              "If you did not mean to use an optional you can use '\\(' to escape the '('"
            )
          }
        }
        paste0("(?:", rewrite_all(node$nodes, collapse = "|"), ")")
      },
      alternative = rewrite_all(node$nodes),
      parameter = {
        name <- paste(vapply(node$nodes, \(n) n$text, character(1)), collapse = "")
        parameter <- if (name == "") ANONYMOUS else parameters[[name]]
        if (is.null(parameter)) {
          fail(
            node,
            paste0("Undefined parameter type '", name, "'"),
            paste0("Please register a ParameterType for '", name, "'"),
            class = "cucumber_undefined_parameter_type",
            parameter_type = name
          )
        }
        used <<- c(used, list(parameter))
        regexps <- parameter$regexp
        if (length(regexps) == 1) {
          paste0("(", regexps, ")")
        } else {
          paste0("((?:", paste(regexps, collapse = ")|(?:"), "))")
        }
      },
      expression = paste0("^", rewrite_all(node$nodes), "$")
    )
  }

  pattern <- rewrite(parse_expression(expression))
  structure(pattern, parameters = used)
}

#' Generate Cucumber Expressions that match a step's text
#'
#' Each value that a parameter type used for snippets matches, as a whole
#' word, becomes a parameter. A value that several parameter types match, like
#' `5` for `{int}` and `{float}`, gives one expression per parameter type.
#'
#' @return A list of expressions, each a list with its `expression` and the
#'   `parameters` it uses.
#' @keywords internal
#' @noRd
#' @importFrom stringr str_locate str_sub str_detect str_replace_all
generate_expressions <- function(text, parameters) {
  matchers <- list()
  for (parameter in Filter(\(p) p$use_for_snippets, parameters)) {
    for (regexp in parameter$regexp) {
      matchers <- c(matchers, list(list(parameter = parameter, regexp = regexp)))
    }
  }
  is_boundary <- function(i) {
    i < 1 || i > nchar(text) ||
      str_detect(str_sub(text, i, i), "[\\p{Z}\\p{P}\\p{S}]")
  }
  # The first match at or after `from` that is a whole word
  find <- function(regexp, from) {
    for (position in seq(from, nchar(text))) {
      location <- str_locate(str_sub(text, position), paste0("(", regexp, ")"))
      if (is.na(location[1])) return(NULL)
      start <- position + location[1] - 1
      end <- position + location[2] - 1
      if (end >= start && is_boundary(start - 1) && is_boundary(end + 1)) {
        return(c(start = start, end = end))
      }
    }
    NULL
  }
  # Escape Cucumber Expression syntax
  escape <- function(x) str_replace_all(x, "([\\\\({/])", "\\\\\\1")

  literals <- character()
  choices <- list()
  position <- 1
  while (position <= nchar(text)) {
    found <- lapply(matchers, \(m) find(m$regexp, position))
    keep <- !vapply(found, is.null, logical(1))
    if (!any(keep)) break
    found <- found[keep]
    starts <- vapply(found, \(f) f[["start"]], numeric(1))
    lengths <- vapply(found, \(f) f[["end"]] - f[["start"]] + 1, numeric(1))
    start <- min(starts)
    length <- max(lengths[starts == start])
    best <- lapply(matchers[keep][starts == start & lengths == length], \(m) m$parameter)
    best <- best[!duplicated(vapply(best, \(p) p$name, character(1)))]
    # Preferential parameter types first, then by name
    best <- best[order(
      !vapply(best, \(p) p$prefer_for_regexp_match, logical(1)),
      vapply(best, \(p) p$name, character(1))
    )]
    literals <- c(literals, escape(str_sub(text, position, start - 1)))
    choices <- c(choices, list(best))
    position <- start + length
  }
  literals <- c(literals, escape(str_sub(text, position)))

  # Every combination of parameter types, varying the last parameter fastest,
  # capped at 256 like the official generator
  combinations <- list(list())
  for (choice in choices) {
    combinations <- unlist(
      lapply(combinations, \(used) lapply(choice, \(p) c(used, list(p)))),
      recursive = FALSE
    )
  }
  lapply(utils::head(combinations, 256), \(used) {
    names <- vapply(used, \(p) paste0("{", p$name, "}"), character(1))
    list(
      expression = paste0(c(rbind(literals, c(names, ""))), collapse = ""),
      parameters = used
    )
  })
}

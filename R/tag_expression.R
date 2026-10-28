#' Parse and evaluate tag expressions
#'
#' @description
#' Tag expressions are boolean expressions that can be used to filter scenarios,
#' parsed like the official [cucumber/tag-expressions](https://github.com/cucumber/tag-expressions).
#' They support the following operators:
#' - `and` - logical AND
#' - `or` - logical OR
#' - `not` - logical NOT
#' - `()` - parentheses for grouping
#'
#' A tag is everything up to whitespace or a parenthesis, and is matched as written, with its `@`.
#' A backslash escapes a parenthesis, whitespace or a backslash in a tag.
#'
#' @param expression A tag expression string (e.g., "@smoke and not @slow")
#' @param scenario_tags A character vector of tags for a scenario (without @ prefix)
#' @return A logical value indicating whether the scenario matches the expression
#' @keywords internal
#' @noRd
#' @examples \dontrun{
#' evaluate_tag_expression("@smoke and not @slow", c("smoke", "fast"))  # TRUE
#' evaluate_tag_expression("@smoke and not @slow", c("smoke", "slow"))  # FALSE
#' evaluate_tag_expression("@smoke or @fast", c("fast"))  # TRUE
#' }
evaluate_tag_expression <- function(expression, scenario_tags) {
  if (is.null(expression) || length(expression) == 0) {
    return(TRUE)
  }
  match_tag_expression(expression, paste0("@", scenario_tags, recycle0 = TRUE))
}

#' Whether tags, as written, match a tag expression
#' @keywords internal
#' @noRd
match_tag_expression <- function(expression, tags) {
  eval_tag_ast(parse_tag_expression(expression), tags)
}

TAG_OPERATORS <- c("or", "and", "not")
TAG_PRECEDENCE <- c("(" = -2, ")" = -1, or = 0, and = 1, not = 2)

#' Parse a tag expression into an AST, with the shunting-yard algorithm of the
#' official implementation
#' @keywords internal
#' @noRd
parse_tag_expression <- function(expression) {
  syntax_error <- function(message) {
    abort_user(
      sprintf('Tag expression "%s" could not be parsed because of syntax error: %s', expression, message)
    )
  }
  expect <- function(expected, actual) {
    if (expected != actual) syntax_error(sprintf("Expected %s.", expected))
  }

  tokens <- tokenize_tag_expression(expression, syntax_error)
  if (length(tokens) == 0) {
    return(list(type = "true"))
  }

  expressions <- list()
  operators <- character()
  push_expression <- function(operator) {
    arity <- if (operator == "not") 1 else 2
    if (length(expressions) < arity) syntax_error("Expected operand.")
    n <- length(expressions)
    node <- if (arity == 1) {
      list(type = "not", operand = expressions[[n]])
    } else {
      list(type = operator, left = expressions[[n - 1]], right = expressions[[n]])
    }
    expressions <<- c(expressions[seq_len(n - arity)], list(node))
  }
  pop_operator <- function() {
    operator <- operators[[length(operators)]]
    operators <<- operators[-length(operators)]
    operator
  }
  peek <- function() operators[[length(operators)]]

  expected <- "operand"
  for (token in tokens) {
    if (token %in% c("not", "(")) {
      expect(expected, "operand")
      operators <- c(operators, token)
      expected <- "operand"
    } else if (token %in% c("and", "or")) {
      expect(expected, "operator")
      # Both are left associative
      while (length(operators) > 0 && peek() %in% TAG_OPERATORS &&
               TAG_PRECEDENCE[[token]] <= TAG_PRECEDENCE[[peek()]]) {
        push_expression(pop_operator())
      }
      operators <- c(operators, token)
      expected <- "operand"
    } else if (token == ")") {
      expect(expected, "operator")
      while (length(operators) > 0 && peek() != "(") {
        push_expression(pop_operator())
      }
      if (length(operators) == 0) syntax_error("Unmatched ).")
      pop_operator()
      expected <- "operator"
    } else {
      expect(expected, "operand")
      expressions <- c(expressions, list(list(type = "tag", value = token)))
      expected <- "operator"
    }
  }

  while (length(operators) > 0) {
    if (peek() == "(") syntax_error("Unmatched (.")
    push_expression(pop_operator())
  }

  expressions[[1]]
}

#' Split a tag expression into tags, operators and parentheses. A backslash
#' escapes a parenthesis, whitespace or a backslash.
#' @keywords internal
#' @noRd
tokenize_tag_expression <- function(expression, syntax_error) {
  tokens <- character()
  token <- ""
  escaped <- FALSE
  for (char in strsplit(expression, "")[[1]]) {
    if (escaped) {
      if (!char %in% c("(", ")", "\\") && !grepl("\\s", char)) {
        syntax_error(sprintf('Illegal escape before "%s".', char))
      }
      token <- paste0(token, char)
      escaped <- FALSE
    } else if (char == "\\") {
      escaped <- TRUE
    } else if (char %in% c("(", ")") || grepl("\\s", char)) {
      if (nchar(token) > 0) tokens <- c(tokens, token)
      token <- ""
      if (!grepl("\\s", char)) tokens <- c(tokens, char)
    } else {
      token <- paste0(token, char)
    }
  }
  if (nchar(token) > 0) tokens <- c(tokens, token)
  tokens
}

#' Evaluate a tag expression AST
#' @keywords internal
#' @noRd
eval_tag_ast <- function(ast, tags) {
  switch(
    ast$type,
    "true" = TRUE,
    "tag" = ast$value %in% tags,
    "not" = !eval_tag_ast(ast$operand, tags),
    "and" = eval_tag_ast(ast$left, tags) && eval_tag_ast(ast$right, tags),
    "or" = eval_tag_ast(ast$left, tags) || eval_tag_ast(ast$right, tags)
  )
}

#' Check that `tags` of a run or a hook is one tag expression, or `NULL`
#' @keywords internal
#' @noRd
check_tags <- function(tags, call = NULL) {
  if (is.null(tags) || checkmate::test_string(tags)) {
    # Fail before the run on an invalid tag expression, not when the first scenario is matched
    evaluate_tag_expression(tags, character())
    return(invisible(tags))
  }
  abort(
    "`tags` must be one tag expression.",
    body = c(i = 'Combine tag expressions with `and`, like `"@smoke and not @slow"`.'),
    call = call,
    trace = empty_trace()
  )
}

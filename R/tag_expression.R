#' Parse and evaluate tag expressions
#'
#' @description
#' Tag expressions are boolean expressions that can be used to filter scenarios.
#' They support the following operators:
#' - `and` - logical AND
#' - `or` - logical OR
#' - `not` - logical NOT
#' - `()` - parentheses for grouping
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

  # Remove @ symbols from the expression
  expr <- gsub("@", "", expression)

  # Tokenize the expression
  tokens <- tokenize_tag_expression(expr)

  # Parse into an AST
  ast <- parse_tag_tokens(tokens)

  # Evaluate the AST
  eval_tag_ast(ast, scenario_tags)
}

#' Tokenize a tag expression
#' @keywords internal
#' @noRd
tokenize_tag_expression <- function(expr) {
  # Remove extra whitespace
  expr <- trimws(expr)

  tokens <- list()
  i <- 1
  n <- nchar(expr)

  while (i <= n) {
    char <- substr(expr, i, i)

    # Skip whitespace
    if (grepl("\\s", char)) {
      i <- i + 1
      next
    }

    # Handle parentheses
    if (char == "(") {
      tokens <- c(tokens, list(list(type = "lparen", value = "(")))
      i <- i + 1
      next
    }

    if (char == ")") {
      tokens <- c(tokens, list(list(type = "rparen", value = ")")))
      i <- i + 1
      next
    }

    # Try to match a keyword (and, or, not)
    remaining <- substr(expr, i, n)

    if (grepl("^and\\b", remaining, ignore.case = TRUE)) {
      tokens <- c(tokens, list(list(type = "and", value = "and")))
      i <- i + 3
      next
    }

    if (grepl("^or\\b", remaining, ignore.case = TRUE)) {
      tokens <- c(tokens, list(list(type = "or", value = "or")))
      i <- i + 2
      next
    }

    if (grepl("^not\\b", remaining, ignore.case = TRUE)) {
      tokens <- c(tokens, list(list(type = "not", value = "not")))
      i <- i + 3
      next
    }

    # Match a tag (alphanumeric, underscore, hyphen, and dot)
    match <- regexpr("^[[:alnum:]_.-]+", remaining)
    if (match > 0) {
      tag_name <- regmatches(remaining, match)
      tokens <- c(tokens, list(list(type = "tag", value = tag_name)))
      i <- i + attr(match, "match.length")
      next
    }

    # Unexpected character
    rlang::abort(sprintf("Unexpected character '%s' at position %d in tag expression", char, i))
  }

  tokens
}

#' Parse tag tokens into an AST
#' @keywords internal
#' @noRd
parse_tag_tokens <- function(tokens) {
  pos <- 1

  # Parse OR expression (lowest precedence)
  parse_or <- function() {
    left <- parse_and()

    while (pos <= length(tokens) && tokens[[pos]]$type == "or") {
      pos <<- pos + 1
      right <- parse_and()
      left <- list(type = "or", left = left, right = right)
    }

    left
  }

  # Parse AND expression (higher precedence than OR)
  parse_and <- function() {
    left <- parse_not()

    while (pos <= length(tokens) && tokens[[pos]]$type == "and") {
      pos <<- pos + 1
      right <- parse_not()
      left <- list(type = "and", left = left, right = right)
    }

    left
  }

  # Parse NOT expression (highest precedence)
  parse_not <- function() {
    if (pos <= length(tokens) && tokens[[pos]]$type == "not") {
      pos <<- pos + 1
      operand <- parse_primary()
      return(list(type = "not", operand = operand))
    }

    parse_primary()
  }

  # Parse primary expression (tag or parenthesized expression)
  parse_primary <- function() {
    if (pos > length(tokens)) {
      rlang::abort("Unexpected end of tag expression")
    }

    token <- tokens[[pos]]

    if (token$type == "lparen") {
      pos <<- pos + 1
      expr <- parse_or()

      if (pos > length(tokens) || tokens[[pos]]$type != "rparen") {
        rlang::abort("Missing closing parenthesis in tag expression")
      }

      pos <<- pos + 1
      return(expr)
    }

    if (token$type == "tag") {
      pos <<- pos + 1
      return(list(type = "tag", value = token$value))
    }

    rlang::abort(sprintf("Unexpected token '%s' in tag expression", token$value))
  }

  if (length(tokens) == 0) {
    return(list(type = "literal", value = TRUE))
  }

  ast <- parse_or()

  if (pos <= length(tokens)) {
    rlang::abort(sprintf("Unexpected token '%s' after complete expression", tokens[[pos]]$value))
  }

  ast
}

#' Evaluate a tag expression AST
#' @keywords internal
#' @noRd
eval_tag_ast <- function(ast, scenario_tags) {
  switch(
    ast$type,
    "literal" = ast$value,
    "tag" = ast$value %in% scenario_tags,
    "not" = !eval_tag_ast(ast$operand, scenario_tags),
    "and" = eval_tag_ast(ast$left, scenario_tags) && eval_tag_ast(ast$right, scenario_tags),
    "or" = eval_tag_ast(ast$left, scenario_tags) || eval_tag_ast(ast$right, scenario_tags),
    rlang::abort(sprintf("Unknown AST node type: %s", ast$type))
  )
}

#' Convert a Cucumber Expression to a regular expression
#'
#' Text is matched literally, `(text)` is optional, `a/b` matches either word,
#' `{name}` matches a parameter and `{}` matches anything.
#' `\(`, `\{` and `\/` match the character literally.
#'
#' @return A regular expression, with the names of matched parameters, in order,
#'   in the `parameters` attribute (`""` for `{}`).
#' @keywords internal
#' @noRd
#' @importFrom stringr str_match_all str_replace_all str_replace
expression_to_pattern <- function(x, parameters = get_parameters()) {
  # Private use characters stand in for escapes and parameters while the
  # expression is rewritten, so their text isn't treated as syntax
  escapes <- c(
    "\\\\" = "\uE000",
    "\\(" = "\uE001",
    "\\)" = "\uE002",
    "\\{" = "\uE003",
    "\\}" = "\uE004",
    "\\/" = "\uE005"
  )
  for (escape in names(escapes)) {
    x <- gsub(escape, escapes[[escape]], x, fixed = TRUE)
  }

  parameter_names <- str_match_all(x, "\\{([^{}]*)\\}")[[1]][, 2]
  x <- str_replace_all(x, "\\{[^{}]*\\}", "\uE006")

  x <- str_replace_all(x, "\\(([^()]*)\\)", "\uE007\\1\uE008")
  x <- str_replace_all(x, "([.\\\\|?*+^$(){}\\[\\]])", "\\\\\\1")
  x <- str_replace_all(x, c("\uE007" = "(?:", "\uE008" = ")?"))
  # ponytail: an alternative is a run of non-space text, so "/about" or
  # "{int}/{int}" stay literal instead of erroring like cucumber-js does
  x <- str_replace_all(
    x,
    "[^\\s/\uE006]+(?:/[^\\s/\uE006]+)+",
    \(alternation) {
      paste0("(?:", gsub("/", "|", alternation, fixed = TRUE), ")")
    }
  )

  for (name in parameter_names) {
    parameter <- Find(\(parameter) parameter$name == name, parameters)
    if (name != "" && is.null(parameter)) {
      abort(glue("Undefined parameter type: {{{name}}}"), trace = empty_trace())
    }
    regexp <- if (name == "") ".*" else parameter$regexp
    # A replacement string, so a parameter's regexp is unescaped once,
    # as `define_parameter_type()` documents
    x <- str_replace(x, "\uE006", paste0("(", regexp, ")"))
  }

  literals <- c("\\\\", "\\(", "\\)", "\\{", "\\}", "/")
  for (i in seq_along(escapes)) {
    x <- gsub(escapes[[i]], literals[[i]], x, fixed = TRUE)
  }
  structure(x, parameters = parameter_names)
}

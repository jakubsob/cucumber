#' @importFrom rlang list2
.parameters <- function(...) {
  structure(list2(...), class = "parameters")
}

.parameter <- function(
  name,
  regexp,
  transformer = \(x, ...) x,
  use_for_snippets = TRUE,
  prefer_for_regexp_match = FALSE
) {
  structure(
    list(
      name = name,
      regexp = regexp,
      transformer = transformer,
      use_for_snippets = use_for_snippets,
      prefer_for_regexp_match = prefer_for_regexp_match
    ),
    class = "parameter"
  )
}

# `{}` matches anything and passes it as text
ANONYMOUS <- .parameter(
  name = "",
  regexp = ".*",
  transformer = \(x) x,
  use_for_snippets = FALSE,
  prefer_for_regexp_match = TRUE
)

#' Define extra parameters to use in Cucumber steps.
#'
#' @description
#' Built-in parameter types are `{int}`, `{float}`, `{word}`, `{string}` and the anonymous `{}`.
#' `{byte}` and `{short}` match and convert like `{int}`, and `{double}` like `{float}`. `{long}` matches
#' like `{int}` but gives a double, as a long can be too big for an R integer.
#' Define your own before the steps that use it are run, e.g. in a `setup-*.R` file.
#'
#' @param name
#'  The name of the parameter.
#' @param regexp
#'   A regular expression that the parameter will match on, or a character vector of them to match any of them.
#' @param transformer
#'  A function that will transform the parameter from a string to the desired type.
#'  If `regexp` has capture groups, the transformer gets the text of each of them as a separate argument
#'  instead of the whole match. Use non-capturing groups, `(?:...)`, to pass the whole match.
#'  Defaults to passing the text as it is, the text of the first capture group if `regexp` has any.
#' @param use_for_snippets
#'  Whether to use this parameter type in snippets suggested for undefined steps.
#' @param prefer_for_regexp_match
#'  Whether to use this parameter type for a regular expression step definition's capture group
#'  whose regexp is the same as the regexp of another parameter type.
#' @return An object of class \code{parameter}, invisibly. Function should be called for side effects.
#'
#' @examples
#' define_parameter_type("color", "red|blue|green", as.character)
#' define_parameter_type(
#'   name = "sci_number",
#'   regexp = "[+-]?\\d*\\.?\\d+(?:e[+-]?\\d+)?",
#'   transformer = as.double
#' )
#'
#' @eval features_rd(features = "parameter_types.feature")
#'
#' @md
#' @importFrom checkmate assert_string assert_character assert_function assert_flag
#' @export
define_parameter_type <- function(
  name,
  regexp,
  transformer = \(x, ...) x,
  use_for_snippets = TRUE,
  prefer_for_regexp_match = FALSE
) {
  assert_string(name)
  assert_character(regexp, min.len = 1, any.missing = FALSE)
  assert_function(transformer)
  assert_flag(use_for_snippets)
  assert_flag(prefer_for_regexp_match)
  parameters <- get_parameters()
  parameter <- .parameter(
    name,
    regexp,
    transformer,
    use_for_snippets,
    prefer_for_regexp_match
  )
  # A parameter type defined again the same, like by a setup file loaded again, replaces itself
  if (same_parameter_type(parameters[[name]], parameter)) parameters[[name]] <- NULL
  check_parameter_type(parameter, parameters)
  parameter$order <- next_registration()
  parameters[[name]] <- parameter
  set_parameters(parameters)
  invisible(parameter)
}

#' Whether two parameter types are defined the same, their transformers by
#' their code, not the environment they're defined in
#' @keywords internal
#' @noRd
same_parameter_type <- function(parameter, other) {
  fields <- c("name", "regexp", "use_for_snippets", "prefer_for_regexp_match")
  !is.null(parameter) &&
    identical(parameter[fields], other[fields]) &&
    identical(parameter$transformer, other$transformer, ignore.environment = TRUE)
}

#' Fail like cucumber-expressions' ParameterTypeRegistry on a parameter type
#' that can't be added to the others
#' @keywords internal
#' @noRd
check_parameter_type <- function(parameter, parameters) {
  fail <- function(message) abort_user(message, class = "cucumber_expression_error")
  if (grepl("[{}()\\\\/]", parameter$name)) {
    fail(paste0(
      "Illegal character in parameter name {", parameter$name, "}. ",
      "Parameter names may not contain '{', '}', '(', ')', '\\' or '/'"
    ))
  }
  # cucumber-expressions says "There is already a parameter type with name ",
  # as the anonymous parameter type is named ""
  if (parameter$name == "") {
    fail("A parameter type must have a name, as {} is the anonymous parameter type.")
  }
  if (!is.null(parameters[[parameter$name]])) {
    fail(paste0("There is already a parameter type with name ", parameter$name))
  }
  for (regexp in parameter$regexp) {
    problem <- regex_problem(regexp)
    if (!is.null(problem)) {
      abort_user(
        paste0("The regexp /", regexp, "/ of parameter type {", parameter$name, "} is invalid."),
        body = c(x = problem),
        class = "cucumber_expression_error"
      )
    }
  }
  if (parameter$prefer_for_regexp_match) {
    for (existing in parameters) {
      regexp <- intersect(existing$regexp, parameter$regexp)
      if (existing$prefer_for_regexp_match && length(regexp) > 0) {
        fail(paste0(
          "There can only be one preferential parameter type per regexp. ",
          "The regexp /", regexp[[1]], "/ is used for two preferential parameter types, ",
          "{", existing$name, "} and {", parameter$name, "}"
        ))
      }
    }
  }
}

#' Transform the text a parameter matched with its parameter type's transformer.
#' Its error says which parameter type failed, with the backtrace of the
#' transformer, like the error of a step, see `call_step()`.
#' @param text The text the parameter matched
#' @param values The text of each of its capture groups, or `text`
#' @keywords internal
#' @noRd
transform_parameter <- function(parameter, text, values) {
  withCallingHandlers(
    call_step(parameter$transformer, as.list(values)),
    error = function(e) {
      abort(
        glue("Parameter type {{{parameter$name}}} failed to transform {encodeString(text, quote = '\"')}."),
        parent = e,
        call = NULL,
        trace = rlang::cnd_entrace(e)$trace
      )
    }
  )
}

#' Convert text to an integer, failing instead of returning NA when it's out of range
#' @noRd
as_integer <- function(x) {
  value <- suppressWarnings(as.integer(x))
  if (is.na(value) && !is.na(x)) {
    abort_user("It's out of the range of an R integer.")
  }
  value
}

set_default_parameters <- function() {
  set_parameters(.parameters())
  integer <- c("-?\\d+", "\\d+")
  define_parameter_type("int", integer, as_integer, prefer_for_regexp_match = TRUE)
  float <- "[-+]?(?:[0-9]+(?:[.][0-9]+)?|[.][0-9]+)(?:[E][-+]?[0-9]+)?"
  define_parameter_type("float", float, as.double)
  define_parameter_type("word", "[^\\s]+", as.character, use_for_snippets = FALSE)
  define_parameter_type(
    "string",
    c('"([^"\\\\]*(\\\\.[^"\\\\]*)*)"', "'([^'\\\\]*(\\\\.[^'\\\\]*)*)'"),
    function(double_quoted, single_quoted) {
      value <- if (is.na(double_quoted)) single_quoted else double_quoted
      value <- gsub('\\"', '"', value, fixed = TRUE)
      gsub("\\'", "'", value, fixed = TRUE)
    }
  )
  define_parameter_type("double", float, as.double, use_for_snippets = FALSE)
  define_parameter_type("byte", integer, as_integer, use_for_snippets = FALSE)
  define_parameter_type("short", integer, as_integer, use_for_snippets = FALSE)
  # A long can be too big for an R integer
  define_parameter_type("long", integer, as.double, use_for_snippets = FALSE)
  # Built-in parameter types aren't reported in Cucumber Messages
  parameters <- get_parameters()
  for (name in names(parameters)) {
    parameters[[name]]$builtin <- TRUE
  }
  set_parameters(parameters)
}

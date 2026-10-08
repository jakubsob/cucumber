#' @importFrom rlang list2
.parameters <- function(...) {
  structure(list2(...), class = "parameters")
}

#' @importFrom checkmate assert_string assert_character assert_function assert_flag
.parameter <- function(
  name,
  regexp,
  transformer,
  use_for_snippets = TRUE,
  prefer_for_regexp_match = FALSE
) {
  assert_string(name)
  assert_character(regexp, min.len = 1, any.missing = FALSE)
  assert_function(transformer)
  assert_flag(use_for_snippets)
  assert_flag(prefer_for_regexp_match)
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
#' The following parameter types are available by default:
#'
#' | **Type**           | **Description**                                                                                                                                         |
#' | ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
#' | `{int}`            | Matches integers, for example `71` or `-19`. Converts value with `as.integer`, failing the step if it's out of range.                                    |
#' | `{float}`          | Matches floats, for example `3.6`, `.8`, `-9.2` or `1.5E3`, and integers like `12`. Converts value with `as.double`.                                    |
#' | `{word}`           | Matches words without whitespace, for example `banana` or `foo-bar` (but not `banana split`).                                                           |
#' | `{string}`         | Matches single-quoted or double-quoted strings, for example `"banana split"` or `'banana split'` (but not `banana split`). Only the text between the quotes is extracted, and escaped quotes in it, like `\"`, are unescaped. |
#' | `{}`               | Matches anything and passes it as text.                                                                                                                  |
#'
#' To use custom parameter types, call `define_parameter_type` before `cucumber::test` is called.
#'
#' @param name
#'  The name of the parameter.
#' @param regexp
#'   A regular expression that the parameter will match on, or a character vector of them to match any of them.
#' @param transformer
#'  A function that will transform the parameter from a string to the desired type.
#'  If `regexp` has capture groups, the transformer gets the text of each of them as a separate argument
#'  instead of the whole match. Use non-capturing groups, `(?:...)`, to pass the whole match.
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
#' \dontrun{
#' #' tests/testthat/test-cucumber.R
#' cucumber::define_parameter_type("color", "red|blue|green", as.character)
#' cucumber::test(".", "./steps")
#' }
#'
#' @md
#' @export
define_parameter_type <- function(
  name,
  regexp,
  transformer,
  use_for_snippets = TRUE,
  prefer_for_regexp_match = FALSE
) {
  parameters <- get_parameters()
  parameter <- .parameter(
    name,
    regexp,
    transformer,
    use_for_snippets,
    prefer_for_regexp_match
  )
  parameters[[name]] <- parameter
  set_parameters(parameters)
  invisible(parameter)
}

get_parameters <- function() {
  getOption(
    getOption(".cucumber_parameters_option"),
    default = .parameters()
  )
}

#' @importFrom rlang list2 `:=`
set_parameters <- function(parameters) {
  options(list2(!!getOption(".cucumber_parameters_option") := parameters))
}

#' Convert text to an integer, failing instead of returning NA when it's out of range
#' @noRd
as_integer <- function(x) {
  value <- suppressWarnings(as.integer(x))
  if (is.na(value) && !is.na(x)) {
    abort(glue("{x} is out of range for an integer"), trace = empty_trace())
  }
  value
}

set_default_parameters <- function() {
  set_parameters(.parameters())
  define_parameter_type(
    "int",
    c("(?:-?\\d+)", "\\d+"),
    as_integer,
    prefer_for_regexp_match = TRUE
  )
  define_parameter_type(
    "float",
    "[-+]?(?:[0-9]+(?:[.][0-9]+)?|[.][0-9]+)(?:[E][-+]?[0-9]+)?",
    as.double
  )
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
}

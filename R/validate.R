#' Validate lines read from a feature file
#' @keywords internal
validate_feature <- function(lines) {
  # Remove comments and empty lines for validation
  clean_lines <- remove_comments(remove_empty_lines(lines))
  clean_lines |>
    validate_indentation() |>
    validate_one_feature_keyword()
  invisible(lines)
}

#' @keywords internal
#' @importFrom stringr str_detect
#' @importFrom cli cli_abort
validate_indentation <- function(lines) {
  indent <- getOption("cucumber.indent", default = "^\\s{2}")
  test_lines <- lines[!str_detect(lines, "^Feature")] |>
    remove_empty_lines()
  if (any(!str_detect(test_lines, indent))) {
    cli_abort(c(
      "All lines must be indented with {indent}",
      "i" = "Check the {.code getOption('cucumber.indent')} option if it is set to your feature file indent."
    ))
  }
  invisible(lines)
}

#' @keywords internal
#' @importFrom stringr str_detect
#' @importFrom cli cli_abort
validate_one_feature_keyword <- function(lines) {
  test_lines <- lines |>
    remove_empty_lines()
  if (sum(str_detect(test_lines, "Feature:")) != 1) {
    cli_abort("Feature file must have exactly one {.field Feature:} keyword.")
  }
  invisible(lines)
}

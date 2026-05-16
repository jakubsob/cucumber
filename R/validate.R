#' Validate lines read from a feature file
#' @keywords internal
validate_feature <- function(lines) {
  # Remove comments and empty lines for validation
  clean_lines <- remove_comments(remove_empty_lines(lines))
  clean_lines <- clean_lines[!special_mask(clean_lines)]
  clean_lines |>
    validate_indentation() |>
    validate_one_feature_keyword() |>
    validate_tag_placement()
  invisible(lines)
}

#' @keywords internal
#' @importFrom stringr str_detect
#' @importFrom cli cli_abort
validate_indentation <- function(lines) {
  indent <- getOption("cucumber.indent", default = "^\\s{2}")
  test_lines <- lines[!str_detect(lines, "^Feature")] |>
    remove_empty_lines()
  test_lines <- test_lines[!special_mask(test_lines)]
  test_lines <- test_lines[!str_detect(test_lines, TAG_LINE_REGEX)]
  if (any(!str_detect(test_lines, indent))) {
    cli_abort(
      c(
        "All lines must be indented with {indent}",
        "i" = "Check the {.code getOption('cucumber.indent')} option if it is set to your feature file indent."
      ),
      trace = empty_trace()
    )
  }
  invisible(lines)
}

#' @keywords internal
#' @importFrom stringr str_detect
#' @importFrom cli cli_abort
validate_one_feature_keyword <- function(lines) {
  test_lines <- lines |>
    remove_empty_lines()
  test_lines <- test_lines[!special_mask(test_lines)]
  if (sum(str_detect(test_lines, "Feature:")) != 1) {
    cli_abort("Feature file must have exactly one {.field Feature:} keyword.", trace = empty_trace())
  }
  invisible(lines)
}

#' @keywords internal
#' @noRd
#' @importFrom stringr str_detect
#' @importFrom cli cli_abort
validate_tag_placement <- function(lines) {
  # Tags can only be placed above: Feature, Scenario, Scenario Outline, Examples
  valid_keywords <- c(
    "Feature",
    "Scenario",
    "Scenario Outline",
    "Examples",
    "Scenarios"
  )

  for (i in seq_along(lines)) {
    if (str_detect(lines[i], TAG_LINE_REGEX)) {
      # Find the next non-tag, non-empty line
      j <- i + 1
      while (
        j <= length(lines) &&
          (str_detect(lines[j], TAG_LINE_REGEX) ||
            str_detect(lines[j], "^\\s*$") ||
            str_detect(lines[j], "^\\s*#"))
      ) {
        j <- j + 1
      }

      if (j <= length(lines)) {
        next_line <- lines[j]
        # Check if next line is a valid keyword for tags
        has_valid_keyword <- any(vapply(
          valid_keywords,
          function(kw) {
            str_detect(next_line, paste0("^\\s*", kw, "\\s*(:|\\s)"))
          },
          logical(1)
        ))

        if (!has_valid_keyword) {
          # Extract the invalid keyword if present
          if (
            str_detect(
              next_line,
              "^\\s*(Background|Given|When|Then|And|But|\\*)\\s*"
            )
          ) {
            invalid_keyword <- sub(
              "^\\s*(Background|Given|When|Then|And|But|\\*)\\s*.*",
              "\\1",
              next_line
            )
            cli_abort(
              c(
                "Tags cannot be placed above {.field {invalid_keyword}} (line {j})",
                "i" = "Tags can only be placed above: Feature, Scenario, Scenario Outline, or Examples",
                "x" = "Tag found at line {i}: {.val {lines[i]}}"
              ),
              trace = empty_trace()
            )
          }
        }
      }
    }
  }

  invisible(lines)
}

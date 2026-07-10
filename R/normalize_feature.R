#' @importFrom stringr str_replace_all str_extract
map_keywords <- function(lines) {
  special <- special_mask(lines)
  # Track the last Given/When/Then keyword for And/But resolution
  last_keyword <- "Step"
  result <- character(length(lines))

  for (i in seq_along(lines)) {
    if (special[i]) {
      result[i] <- lines[i]
      next
    }

    line <- lines[i]
    # Extract the keyword
    keyword <- str_extract(line, "^\\s*(Given|When|Then|And|But|\\*)")
    keyword <- trimws(keyword)

    if (is.na(keyword)) {
      result[i] <- line
      next
    }

    # Update last_keyword if we see Given/When/Then
    if (keyword %in% c("Given", "When", "Then")) {
      last_keyword <- keyword
      result[i] <- line
    } else if (keyword %in% c("And", "But", "*")) {
      # Replace the leading And/But/* with the last Given/When/Then keyword.
      # String surgery, not a regex built from the keyword: `*` is a regex
      # metacharacter and the keyword set is fixed, so escaping is pointless.
      indent <- str_extract(line, "^\\s*")
      rest <- substring(line, nchar(indent) + nchar(keyword) + 1)
      result[i] <- paste0(indent, last_keyword, rest)
    } else {
      result[i] <- line
    }
  }

  # Handle other normalizations (Examples, Scenario Template)
  result <- str_replace_all(
    result,
    c(
      "^(\\s*)Example:" = "\\1Scenario:",
      "^(\\s*)Examples:" = "\\1Scenarios:",
      "^(\\s*)Scenario Template:" = "\\1Scenario Outline:"
    )
  )

  result
}

normalize_feature <- function(lines) {
  lines |>
    map_keywords()
}

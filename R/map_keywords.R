#' @importFrom stringr str_replace_all
map_keywords <- function(lines) {
  str_replace_all(
    lines,
    c(
      "Example:" = "Scenario:",
      "Examples:" = "Scenarios:"
    )
  )
}

fill_keywords <- function(lines) {
  keywords <- c("Given", "When", "Then")
  result <- character(length(lines))
  last_keyword <- NULL

  for (i in seq_along(lines)) {
    line <- lines[i]
    split_line <- strsplit(trimws(line), " ")[[1]]
    keyword <- split_line[1]

    if (keyword %in% keywords) {
      last_keyword <- keyword
    } else if (keyword %in% c("And", "But") && !is.null(last_keyword)) {
      line <- gsub(keyword, last_keyword, line)
    }

    result[i] <- line
  }

  result
}

normalize_feature <- function(lines) {
  lines |>
    map_keywords() |>
    fill_keywords()
}

#' @importFrom stringr str_replace_all
map_keywords <- function(lines) {
  special <- special_mask(lines)
  # Only normalize lines that aren't special
  lines[!special] <- str_replace_all(
    lines[!special],
    c(
      "^(\\s*)And" = "\\1Step",
      "^(\\s*)But" = "\\1Step",
      "^(\\s*)Example:" = "\\1Scenario:",
      "^(\\s*)Examples:" = "\\1Scenarios:",
      "^(\\s*)Given" = "\\1Step",
      "^(\\s*)Scenario Template:" = "\\1Scenario Outline:",
      "^(\\s*)Then" = "\\1Step",
      "^(\\s*)When" = "\\1Step",
      "^(\\s*)\\*" = "\\1Step"
    )
  )

  lines
}

normalize_feature <- function(lines) {
  lines |>
    map_keywords()
}

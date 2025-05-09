#' @importFrom stringr str_replace_all
map_keywords <- function(lines) {
  special <- special_mask(lines)
  # Only normalize lines that aren't special
  lines[!special] <- str_replace_all(
    lines[!special],
    c(
      "And" = "Step",
      "But" = "Step",
      "Example:" = "Scenario:",
      "Examples:" = "Scenarios:",
      "Given" = "Step",
      "Scenario Template:" = "Scenario Outline:",
      "Then" = "Step",
      "When" = "Step",
      "[*]" = "Step"
    )
  )

  lines
}

normalize_feature <- function(lines) {
  lines |>
    map_keywords()
}

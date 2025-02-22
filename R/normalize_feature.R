#' @importFrom stringr str_replace_all
map_keywords <- function(lines) {
  str_replace_all(
    lines,
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
}

normalize_feature <- function(lines) {
  lines |>
    map_keywords()
}

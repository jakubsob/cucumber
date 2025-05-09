#' @importFrom stringr str_replace_all
map_keywords <- function(lines) {
  state <- new.env()
  state$inside_docstring <- FALSE

  special <- purrr::map_lgl(lines, function(x) {
    # Check if this is a docstring boundary line
    is_docstring_boundary <- detect_docstring_start(x)

    # Check if this is a table line
    is_table_line <- detect_table_start(x)

    if (is_docstring_boundary) {
      # Toggle the docstring state when we hit a boundary
      state$inside_docstring <- !state$inside_docstring
      return(TRUE) # Mark docstring boundary as special
    }

    # Mark table lines as special
    if (is_table_line) {
      return(TRUE)
    }

    # Return docstring state for non-boundary, non-table lines
    return(state$inside_docstring)
  })

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

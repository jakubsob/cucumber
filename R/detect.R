#' @importFrom stringr str_detect
detect_table_start <- function(x) {
  str_detect(x, "^\\s*\\|.*\\|\\s*$")
}

#' @importFrom stringr str_detect
#' @importFrom checkmate test_character
detect_table <- function(x) {
  if (!test_character(x, min.len = 1, any.missing = FALSE)) {
    return(FALSE)
  }
  all(str_detect(x, "^\\s*\\|.*\\|\\s*$"))
}

#' @importFrom stringr str_detect
detect_docstring_start <- function(x) {
  str_detect(x, "^\\s*```|^\\s*\"\"\"$")
}

#' @importFrom stringr str_detect
#' @importFrom checkmate test_character
detect_docstring <- function(x) {
  if (!test_character(x, min.len = 2, any.missing = FALSE)) {
    return(FALSE)
  }
  all(
    c(
      str_detect(x[1], "^\\s*```|^\\s*\"\"\"$"),
      str_detect(x[length(x)], "^\\s*```|^\\s*\"\"\"$")
    )
  )
}

#' Check if line is inside a docstring or table
#' @noRd
special_mask <- function(lines) {
  state <- new.env()
  state$inside_docstring <- FALSE
  purrr::map_lgl(lines, function(x) {
    is_docstring_boundary <- detect_docstring_start(x)
    is_table_line <- detect_table_start(x)

    if (is_docstring_boundary) {
      state$inside_docstring <- !state$inside_docstring
      return(TRUE)
    }

    if (is_table_line) {
      return(TRUE)
    }

    return(state$inside_docstring)
  })
}

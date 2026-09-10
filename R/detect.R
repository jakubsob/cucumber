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

#' Extract the docstring delimiter of a line, or NA if it is not one
#' @importFrom stringr str_match
#' @noRd
docstring_delimiter <- function(x) {
  str_match(x, "^\\s*(```|\"\"\"$)")[, 2]
}

#' Number each line with the docstring block it belongs to, 0 when outside.
#' Delimiters are included in their block and a block is only closed by the
#' same delimiter that opened it, so a docstring may quote the other delimiter.
#' @noRd
docstring_blocks <- function(lines) {
  open <- NA_character_
  block <- 0L
  vapply(
    lines,
    function(x) {
      delimiter <- docstring_delimiter(x)
      if (is.na(open)) {
        if (is.na(delimiter)) {
          return(0L)
        }
        open <<- delimiter
        block <<- block + 1L
      } else if (!is.na(delimiter) && delimiter == open) {
        open <<- NA_character_
      }
      block
    },
    integer(1),
    USE.NAMES = FALSE
  )
}

#' Check if line is inside a docstring or table
#' @noRd
special_mask <- function(lines) {
  docstring_blocks(lines) > 0 | detect_table_start(lines)
}

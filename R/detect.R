#' @importFrom stringr str_detect
#' @importFrom checkmate test_character
detect_table <- function(x) {
  if (!test_character(x, min.len = 1, any.missing = FALSE)) {
    return(FALSE)
  }
  all(str_detect(x, "^\\s*\\|.*\\|\\s*$"))
}

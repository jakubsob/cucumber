#' @importFrom checkmate assert_character
parse_docstring <- function(x) {
  assert_character(x, min.len = 2, any.missing = FALSE)
  x[-c(1, length(x))]
}

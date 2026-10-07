#' Build a data table from table rows, the first one being the header
#' @param rows List of character vectors, one per row, all of the same length
#' @importFrom tibble as_tibble
#' @noRd
parse_table <- function(rows) {
  header <- rows[[1]]
  values <- matrix(
    as.character(unlist(rows[-1])),
    ncol = length(header),
    byrow = TRUE,
    dimnames = list(NULL, header)
  )
  # Keep empty and duplicated column names as written
  as_tibble(values, .name_repair = "minimal")
}

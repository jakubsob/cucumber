#' @importFrom stringr str_trim str_split str_replace_all
#' @importFrom purrr map set_names
#' @importFrom tibble as_tibble tibble
#' @importFrom dplyr bind_cols
#' @importFrom checkmate assert_character
parse_table <- function(lines) {
  assert_character(lines, min.len = 1)
  # Split on unescaped pipes and process each cell
  rows <- lines |>
    map(\(x) str_split(x, "(?<!\\\\)\\|")[[1]]) |>
    # Remove first and last pipe split
    map(\(x) x[c(-1, -length(x))]) |>
    map(str_trim) |>
    # Un-escape any escaped pipes in cells
    map(\(x) str_replace_all(x, "\\\\\\|", "\\|"))

  ncols <- length(rows[[1]])
  nrow <- length(rows) - 1
  if (nrow == 0) {
    header <- set_names(rows[[1]], rows[[1]]) |>
      map(\(x) character()) |>
      bind_cols()
    return(header)
  }

  matrix(
    unlist(rows[-1]),
    dimnames = list(
      seq_len(nrow),
      unlist(rows[1])
    ),
    byrow = TRUE,
    nrow = nrow,
    ncol = ncols
  ) |>
    as_tibble()
}

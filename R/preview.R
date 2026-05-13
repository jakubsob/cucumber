#' Preview test cases without executing them
#'
#' @description
#' Performs a dry run by parsing feature files and creating pickles
#' without executing them. Useful for debugging and seeing what tests
#' would be run.
#'
#' @param path Path to the directory containing the `.feature` files.
#' @param filter If not NULL, only features with file names matching this
#'   regular expression will be processed.
#' @param tags If not NULL, filter scenarios by tag expression.
#' @param ... Additional arguments passed to `grepl()`.
#' @return List of pickle objects
#'
#' @examples
#' \dontrun{
#' # Preview all tests
#' pickles <- preview("tests/acceptance")
#'
#' # Preview tests matching a filter
#' pickles <- preview("tests/acceptance", filter = "login")
#'
#' # Preview tests with specific tags
#' pickles <- preview("tests/acceptance", tags = "@smoke and not @slow")
#' }
#'
#' @importFrom purrr map flatten
#' @importFrom rlang abort
#' @importFrom glue glue
#' @keywords internal
#' @noRd
preview <- function(
  path = "tests/acceptance",
  filter = NULL,
  tags = NULL,
  ...
) {
  features <- find_features(path) |>
    filter_features(filter, ...)

  pickles <- features |>
    map(\(feature_path) {
      lines <- readLines(feature_path)
      validated <- validate_feature(lines)
      tokens <- tokenize(validated)  # tokenize handles normalization internally
      pickles <- create_pickles(tokens)
      pickles
    }) |>
    flatten()

  # Filter by tags if provided
  if (!is.null(tags)) {
    pickles <- filter_pickles_by_tags(pickles, tags)
  }

  structure(pickles, class = c("pickle_list", "list"))
}

#' @export
print.pickle_list <- function(x, ...) {
  cat("Preview of", length(x), "test case(s):\n\n")

  for (i in seq_along(x)) {
    cat(glue("[{i}] "))
    print(x[[i]])
    if (i < length(x)) {
      cat("\n")
    }
  }

  invisible(x)
}

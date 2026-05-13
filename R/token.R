#' Create a token object
#'
#' @param type Token type (Feature, Scenario, Scenario Outline, Background, Step, Scenarios)
#' @param value The text value of the token
#' @param tags Character vector of tags
#' @param children List of child token objects
#' @param data Character vector for additional data (tables, docstrings)
#' @return A token object
#' @keywords internal
#' @noRd
#' @importFrom rlang abort
#' @importFrom glue glue
new_token <- function(
  type,
  value = NULL,
  tags = character(),
  children = list(),
  data = NULL
) {
  structure(
    list(
      type = type,
      value = value,
      tags = tags,
      children = children,
      data = data
    ),
    class = "token"
  )
}

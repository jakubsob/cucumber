INDENT <- "^\\s{2}"
NODE_REGEX <- paste0(
  "^(?!\\s+)(",
  paste0(
    c(
      "Feature:",
      "Scenario:", "Example:",
      "Scenarios:", "Examples:",
      "Scenario Outline:", "Scenario Template:",
      "Background:",
      "Given", "When", "Then", "And", "But"
    ),
    collapse = "|"
  ),
  ")(\\s+)?([:print:]*)?"
)

#' @importFrom stringr str_detect
remove_empty_lines <- function(x) {
  x[!str_detect(x, "^$")]
}

#' @importFrom stringr str_detect
remove_comments <- function(x) {
  x[!str_detect(x, "^\\s*#")]
}

#' @importFrom stringr str_remove_all
remove_trailing_colon <- function(x) {
  str_remove_all(x, ":$")
}

#' @importFrom stringr str_remove_all
remove_indent <- function(x) {
  str_remove_all(x, INDENT)
}

#' @importFrom stringr str_detect
detect_node <- function(x) {
  str_detect(x, NODE_REGEX)
}

#' @importFrom stringr str_match
get_node_value <- function(x) {
  str_match(x, NODE_REGEX)[4]
}

#' @importFrom stringr str_match
get_node_type <- function(x) {
  str_match(x, NODE_REGEX)[2]
}

get_data <- function(x) {
  if (length(x) == 0) {
    return(NULL)
  }
  remove_comments(x)
}

#' @importFrom purrr map
tokenize <- function(x) {
  x <- remove_empty_lines(x)
  x <- remove_comments(x)
  indices <- detect_node(x)
  groups <- seq_len(max(cumsum(indices)))
  groups |>
    map(\(ind) {
      text <- x[which(cumsum(indices) == ind)]

      indices <- detect_node(text)
      type <- get_node_type(text[1]) |>
        remove_trailing_colon()
      value <- get_node_value(text[1])
      children <- text[!indices]
      children <- remove_indent(children)

      if (sum(detect_node(children)) == 0) {
        node <- list(
          type = type,
          value = value,
          children = NULL,
          data = get_data(children)
        )
      } else {
        node <- list(
          type = type,
          value = value,
          children = tokenize(children),
          # Get data from lines directly after the node
          data = get_data(children[!cumsum(detect_node(children))])
        )
      }
      node
    })
}

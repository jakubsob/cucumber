NODE_REGEX <- paste0(
  "^(?!\\s+)(",
  paste0(
    c(
      "Feature:",
      "Scenario:", "Example:",
      "Scenarios:", "Examples:",
      "Scenario Outline:", "Scenario Template:",
      "Background:",
      "Step"
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
  str_remove_all(x, getOption("cucumber.indent", default = "^\\s{2}"))
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
  str_remove_all(x, "^\\s*")
}

#' @importFrom purrr map
tokenize <- function(x) {
  x <- normalize_feature(x)
  x <- remove_empty_lines(x)
  x <- remove_comments(x)
  indices <- detect_node(x)
  if (sum(indices) == 0) {
    abort("Error tokenizing Gherkin, no keywords found")
  }
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

    if (type %in% c("Feature", "Scenario", "Background", "Scenario Outline")) {
        return(
          list(
            type = type,
            value = value,
            children = tokenize(children),
            # Store free-form text in data
            data = get_data(children[!cumsum(detect_node(children))])
          )
        )
      } else if (type %in% c("Step", "Scenarios")) {
        return(
          list(
            type = type,
            value = value,
            children = NULL,
            data = get_data(children)
          )
        )
      } else {
        abort(glue("Error tokenizing Gherkin, unknown node type '{type}'"))
      }
    })
}

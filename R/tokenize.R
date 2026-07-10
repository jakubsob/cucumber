NODE_REGEX <- paste0(
  "^(?!\\s+)(",
  paste0(
    c(
      "Feature:",
      "Scenario:", "Example:",
      "Scenarios:", "Examples:",
      "Scenario Outline:", "Scenario Template:",
      "Background:",
      "Given", "When", "Then", "Step"
    ),
    collapse = "|"
  ),
  ")(\\s+)?([:print:]*)?"
)

TAG_LINE_REGEX <- "^\\s*@"

parse_tag_line <- function(line) {
  # Tags can contain alphanumeric, underscore, hyphen, and dot
  tags <- regmatches(line, gregexpr("@[[:alnum:]_.-]+", line))[[1]]
  sub("^@", "", tags)
}

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
  x
}

#' @importFrom purrr map
tokenize <- function(x) {
  x <- normalize_feature(x)
  x <- remove_empty_lines(x)
  x <- remove_comments(x)
  is_tag_line <- grepl(TAG_LINE_REGEX, x)
  indices <- detect_node(x)
  if (sum(indices) == 0) {
    abort("Error tokenizing Gherkin, no keywords found")
  }
  cumulative <- cumsum(indices)
  groups <- seq_len(max(cumulative))
  groups |>
    map(\(ind) {
      group_positions <- which(cumulative == ind)
      text <- x[group_positions]

      # Collect tag lines immediately preceding this group
      first_pos <- group_positions[1]
      tags <- character(0)
      j <- first_pos - 1
      while (j >= 1 && is_tag_line[j]) {
        tags <- c(parse_tag_line(x[j]), tags)
        j <- j - 1
      }

      local_indices <- detect_node(text)
      type <- get_node_type(text[1]) |>
        remove_trailing_colon()
      value <- get_node_value(text[1])
      children <- text[!local_indices]
      children <- remove_indent(children)

      if (type %in% c("Feature", "Scenario", "Background", "Scenario Outline")) {
        pre_node <- children[!cumsum(detect_node(children))]
        return(
          new_token(
            type = type,
            value = value,
            tags = tags,
            children = tokenize(children),
            # Store free-form text in data, excluding tag lines
            data = get_data(pre_node[!grepl(TAG_LINE_REGEX, pre_node)])
          )
        )
      } else if (type %in% c("Step", "Given", "When", "Then")) {
        return(
          new_token(
            type = type,
            value = value,
            data = get_data(children)
          )
        )
      } else if (type == "Scenarios") {
        return(
          new_token(
            type = type,
            value = value,
            tags = tags,
            data = get_data(children[!grepl(TAG_LINE_REGEX, children)])
          )
        )
      }
    })
}

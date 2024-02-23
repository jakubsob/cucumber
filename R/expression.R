#' @importFrom purrr set_names map_chr
#' @importFrom stringr str_replace_all
expression_to_pattern <- function(x, parameters = get_parameters()) {
  replace <- set_names(
    map_chr(parameters, \(x) paste0("(", x$regex, ")")),
    map_chr(parameters, \(x) paste0("\\{", x$name, "\\}"))
  )
  str_replace_all(x, replace)
}

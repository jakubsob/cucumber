options(
  parameters = list(
    extract_type = list(),
    map_type = list(),
    mapper = list()
  )
)

parameter_wrap <- function(x) {
  paste0("\\{", x, "\\}")
}

regex_wrap <- function(x) {
  paste0("(", x, ")")
}

define_parameter_type <- function(name, regexp, transformer) {
  parameters <- getOption("parameters")
  parameters$extract_type[[name]] <- regex_wrap(regexp)
  parameters$map_type[[name]] <- transformer
  parameters$mapper[[parameter_wrap(name)]] <- regex_wrap(regexp)
  options(parameters = parameters)
  invisible(parameters)
}

#' @import stringr
#' @import purrr
extract_params <- function(input, template) {
  parameters <- getOption("parameters")
  mapper <- unlist(parameters$mapper)
  match_template <- str_replace_all(template, mapper)
  find_types_pattern <- paste0(names(mapper), collapse = "|")
  types <- str_extract_all(template, find_types_pattern, TRUE) |>
    str_remove_all("\\{|\\}")
  values <- str_match_all(input, match_template)[[1]][, -1]
  map2(values, types, \(value, type) parameters$map_type[[type]](value))
}

#' @import stringr
find_definition <- function(input, template) {
  parameters <- getOption("parameters")
  find_types_pattern <- paste0(names(parameters$map_type), collapse = "|")
  types <- str_extract_all(template, find_types_pattern, TRUE)
  types_regexes <- map_chr(types, \(x) parameters$extract_type[[x]])

  names(types_regexes) <- paste0("\\{", types, "\\}")
  types_regexes <- types_regexes[!duplicated(types_regexes)]
  match_template <- str_replace_all(template, types_regexes)

  # Use regex to match the template pattern in the input
  str_extract_all(input, match_template) %>% unlist()
}

.parameters <- list()

define_parameter_type <- function(name, regexp, transformer) {
  .parameters[[name]] <<- structure(
    list(
      regexp = regexp,
      transformer = transformer
    ),
    class = "parameter"
  )
}

get_parameter <- function(name) {

}

define_parameter_type(
  name = "int",
  regexp = "([0-9]+)",
  transformer = as.integer
)

define_parameter_type(
  name = "float",
  regexp = "([0-9]+\\.[0-9]+)",
  transformer = as.double
)

define_parameter_type(
  name = "string",
  regexp = "([a-zA-Z]+)",
  transformer = as.character
)

extract_type <- list(
  "{int}" = "([0-9]+)",
  "{float}" = "([0-9]+\\.[0-9]+)",
  "{string}" = "([a-zA-Z]+)"
)

map_type <- list(
  "{int}" = as.integer,
  "{float}" = as.double,
  "{string}" = as.character
)

extract_type <- list(
  "{int}" = "([0-9]+)",
  "{float}" = "([0-9]+\\.[0-9]+)",
  "{string}" = "([a-zA-Z]+)"
)

map_type <- list(
  "{int}" = as.integer,
  "{float}" = as.double,
  "{string}" = as.character
)

#' @importFrom stringr str_extract_all str_extract str_remove_all
#' @importFrom purrr map_chr map2
extract_params <- function(input, template) {
  # Extract the types of the parameters
  types <- str_extract_all(template, "\\{[a-z]+\\}")[[1]]
  types_regexes <- map_chr(types, \(x) extract_type[[x]])
  types_regexes <- paste0("'", types_regexes, "'")

  # Use regex to match the template pattern in the input
  matches <- str_extract(input, types_regexes)
  matches <- str_remove_all(matches, "^'|'$")
  map2(matches, types, \(value, type) map_type[[type]](value))
}

#' @importFrom stringr str_replace_all
find_definition <- function(input, template) {
  types <- str_extract_all(template, "\\{[a-z]+\\}")[[1]]
  types_regexes <- map_chr(types, \(x) extract_type[[x]])
  types <- str_replace_all(types, c("\\{" = "\\\\{", "\\}" = "\\\\}"))
  types_regexes <- paste0("'", types_regexes, "'")
  names(types_regexes) <- types
  types_regexes <- types_regexes[!duplicated(types_regexes)]
  match_template <- str_replace_all(template, types_regexes)

  # Use regex to match the template pattern in the input
  str_extract_all(input, match_template) %>% unlist()
}

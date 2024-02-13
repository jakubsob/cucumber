#' @importFrom rlang abort
#' @importFrom glue glue
parse_token <- function(token, steps, parameters = getOption("parameters")) {
  switch(
    token$type,
    "Scenario" = map(token$children, parse_token, steps = steps, parameters = parameters),
    "Given" = parse_step(token, steps, parameters),
    abort(glue("Unknown token type: {token$type}"))
  )
}

#' @importFrom purrr map_chr map map2 keep pluck
#' @importFrom stringr str_detect str_match_all
#' @importFrom rlang exec
#' @importFrom glue glue
parse_step <- function(token, steps, parameters = getOption("parameters")) {
  # Pattern to detect the step
  detect <- steps |>
    map_chr("description") |>
    map_chr(expression_to_pattern, parameters = parameters)

  description <- paste(token$type, token$value)

  step_mask <- str_detect(description, detect)
  if (sum(step_mask) == 0) {
    abort(glue("No step found for: {description}"))
  }
  if (sum(step_mask) > 1) {
    abort(glue("Multiple steps found for: {description}"))
  }

  step <- steps[step_mask][[1]]

  # Extract parameters names
  parameter_names <- parameters |> map_chr("name") |> paste(collapse = "|")
  parameter_names <- str_match_all(step$description, paste0("\\{(", parameter_names, ")\\}"))[[1]][, 2]
  # Extract parameters values
  values_character <- str_match_all(description, detect)[[1]][, -1]
  params <- map2(values_character, parameter_names, \(value, parameter_name) {
    transformer <- parameters |>
      keep(~ .x$name == parameter_name) |>
      pluck(1, "transformer")
    transformer(value)
  })

  function(context = new.env()) {
    exec(step$implementation, !!!params, context = context)
  }
}

#' @importFrom rlang abort
#' @importFrom glue glue
parse_token <- function(tokens, steps, parameters = getOption("parameters")) {
  map(tokens, \(token) {
    switch(
      token$type,
      "Scenario" = parse_token(token$children, steps, parameters),
      "Feature" = parse_token(token$children, steps, parameters),
      "Given" = parse_step(token, steps, parameters),
      "When" = parse_step(token, steps, parameters),
      "Then" = parse_step(token, steps, parameters),
      abort(glue("Unknown token type: {token$type}"))
    )
  }) |>
    unlist()
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
  values_character <- str_match_all(description, detect[step_mask])[[1]][, -1]
  params <- map2(values_character, parameter_names, \(value, parameter_name) { # nolint: object_usage_linter
    transformer <- parameters |>
      keep(~ .x$name == parameter_name) |>
      pluck(1, "transformer")
    transformer(value)
  })

  function(context = new.env()) {
    names(params) <- names(formals(step$implementation))[-length(formals(step$implementation))]
    exec(step$implementation, context = context, !!!params)
  }
}

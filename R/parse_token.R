#' @importFrom rlang abort call_modify call2
#' @importFrom glue glue
#' @importFrom purrr map walk
#' @importFrom testthat context_start_file test_that
parse_token <- function(tokens, steps, parameters = get_parameters()) {
  map(tokens, \(token) {
    switch(
      token$type,
      "Scenario" = call2(
        function() {
          test_that(glue("Scenario: {token$value}"), {
            context <- new.env()
            calls <- parse_token(token$children, steps, parameters) |>
              map(\(x) call_modify(x, context = context))

            # Use `for` for better error messages instead of purrr indexed ones
            for (call in calls) {
              eval(call)
            }
          })
        }
      ),
      "Feature" = call2(
        function(file_name = token$value) {
          context_start_file(glue("Feature: {file_name}"))
          parse_token(token$children, steps, parameters) |>
            walk(eval)
        }
      ),
      "Given" = parse_step(token, steps, parameters),
      "When" = parse_step(token, steps, parameters),
      "Then" = parse_step(token, steps, parameters),
      abort(glue("Unknown token type: {token$type}"))
    )
  }) |>
    unlist()
}

#' @importFrom purrr map_chr map map_int map2 keep pluck
#' @importFrom stringr str_detect str_match_all
#' @importFrom rlang exec
#' @importFrom glue glue
parse_step <- function(token, steps, parameters = get_parameters()) {
  # Pattern to detect the step
  detect <- steps |>
    map_chr(attr, "detect") |>
    map_chr(expression_to_pattern, parameters = parameters)

  description <- paste(token$type, token$value)

  step_mask <- str_detect(description, detect)
  if (sum(step_mask) == 0) {
    abort(glue("No step found for: \"{description}\""))
  }
  unique_steps <- unique(steps[step_mask])
  are_duplicates <- length(unique_steps) == 1 && length(steps[step_mask]) > 1
  if (are_duplicates) {
    step_description <- attr(unique_steps[[1]], "description")
    abort(
      glue("Multiple steps found for: \"{description}\""),
      body = glue(
        "Check step definitions for duplicates of: \"{step_description}\""
      )
    )
  }
  if (sum(step_mask) > 1) {
    steps <- steps[order(map_int(steps, \(x) length(formals(x))), decreasing = TRUE)]
    map(steps, \(x) parse_step(token, list(x), parameters))
  }

  step <- steps[step_mask][[1]]

  # Extract parameters names
  parameter_names <- parameters |> map_chr("name") |> paste(collapse = "|")
  parameter_names <- str_match_all(attr(step, "detect"), paste0("\\{(", parameter_names, ")\\}"))[[1]][, 2]
  # Extract parameters values
  values_character <- str_match_all(description, detect[step_mask])[[1]][, -1]
  # If there are nested match groups, take the outermost one
  values_character <- values_character[seq_len(length(parameter_names))]
  params <- map2(values_character, parameter_names, \(value, parameter_name) { # nolint: object_usage_linter
    transformer <- parameters |>
      keep(~ .x$name == parameter_name) |>
      pluck(1, "transformer")
    transformer(value)
  })

  if (detect_table(token$data)) {
    params <- append(params, list(parse_table(token$data)))
  } else if (detect_docstring(token$data)) {
    params <- append(params, list(parse_docstring(token$data)))
  }

  impl_formals <- names(formals(step))
  names(params) <- impl_formals[impl_formals != "context"]
  rlang::call2(step, !!!params)
}

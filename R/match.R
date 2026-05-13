#' Match steps in pickles to step definitions
#'
#' @description
#' Enriches pickle steps with matched functions and extracted arguments.
#' Fails early if step definitions are missing or duplicated.
#'
#' @param pickles List of pickle objects
#' @param steps List of step definition functions
#' @param parameters List of parameter type definitions
#' @return List of enriched pickle objects
#' @keywords internal
#' @noRd
#' @importFrom purrr map
match_steps <- function(
  pickles,
  steps = get_steps(),
  parameters = get_parameters()
) {
  pickles |>
    map(\(pickle) {
      pickle$steps <- pickle$steps |>
        map(\(step) {
          match_single_step(step, steps, parameters)
        })
      pickle
    })
}

#' Match a single step to its definition
#'
#' @keywords internal
#' @noRd
#' @importFrom purrr map_chr map2 keep pluck
#' @importFrom stringr str_detect str_match_all
#' @importFrom glue glue
match_single_step <- function(
  step,
  steps = get_steps(),
  parameters = get_parameters()
) {
  # Pattern to detect the step
  detect <- steps |>
    map_chr(attr, "detect") |>
    map_chr(expression_to_pattern, parameters = parameters)

  description <- step$text

  step_mask <- str_detect(description, detect)

  # No matching step found
  if (sum(step_mask) == 0) {
    snippet <- format_step_snippet(description, parameters)
    abort(
      glue("No step found for: \"{description}\""),
      body = c(i = "Add a step definition:", " " = snippet)
    )
  }

  # Check for duplicates
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

  matched_step <- steps[step_mask][[1]]

  # Extract parameter names from step expression
  parameter_names <- parameters |>
    map_chr("name") |>
    paste(collapse = "|")
  parameter_names <- str_match_all(
    attr(matched_step, "detect"),
    paste0("\\{(", parameter_names, ")\\}")
  )[[1]][, 2]

  # Extract parameter values from step text
  values_character <- str_match_all(
    description,
    detect[step_mask]
  )[[1]][, -1]

  # If there are nested match groups, take the outermost one
  values_character <- values_character[seq_len(length(parameter_names))]

  # Transform values using parameter transformers
  params <- map2(
    values_character,
    parameter_names,
    \(value, parameter_name) {
      transformer <- parameters |>
        keep(~ .x$name == parameter_name) |>
        pluck(1, "transformer")
      transformer(value)
    }
  )

  # Add data table or docstring if present
  if (!is.null(step$data_table)) {
    params <- append(params, list(step$data_table))
  } else if (!is.null(step$docstring)) {
    params <- append(params, list(step$docstring))
  }

  # Name parameters according to function formals
  impl_formals <- names(formals(matched_step))
  names(params) <- impl_formals[impl_formals != "context"]

  # Enrich step with matched function and arguments
  step$matched_fn <- matched_step
  step$arguments <- params
  step$definition_location <- attr(matched_step, "srcref")

  step
}

#' Format a step snippet for error messages
#'
#' @keywords internal
#' @noRd
#' @importFrom stringr str_count str_replace_all
#' @importFrom glue glue
format_step_snippet <- function(description, parameters) {
  ordered_names <- intersect(c("string", "float", "int"), names(parameters))
  result <- description
  params_found <- character(0)

  for (type_name in ordered_names) {
    param <- parameters[[type_name]]
    n <- str_count(result, param$regexp)
    if (n > 0) {
      params_found <- c(params_found, rep(type_name, n))
      result <- str_replace_all(
        result,
        param$regexp,
        paste0("{", type_name, "}")
      )
    }
  }

  type_totals <- table(params_found)
  type_seen <- list()
  args <- character(length(params_found))

  for (i in seq_along(params_found)) {
    t <- params_found[[i]]
    type_seen[[t]] <- (type_seen[[t]] %||% 0L) + 1L
    args[[i]] <- if (as.integer(type_totals[[t]]) > 1L) {
      paste0(t, "_", type_seen[[t]])
    } else {
      t
    }
  }

  arg_str <- paste(c(args, "context"), collapse = ", ")
  glue('given("{result}", function({arg_str}) {{\n  pending()\n}})')
}

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
  withCallingHandlers(
    pickles |>
      map(\(pickle) {
        pickle$steps <- pickle$steps |>
          map(\(step) {
            match_single_step(step, steps, parameters)
          })
        pickle
      }),
    purrr_error_indexed = unwrap_purrr_error
  )
}

#' Match a single step to its definition
#'
#' @keywords internal
#' @noRd
#' @importFrom purrr map map_chr map2
#' @importFrom stringr str_detect str_match_all
#' @importFrom glue glue
match_single_step <- function(
  step,
  steps = get_steps(),
  parameters = get_parameters()
) {
  # Pattern to detect the step
  patterns <- steps |>
    map(\(step) expression_to_pattern(attr(step, "description"), parameters))
  detect <- map_chr(patterns, step_regex)

  description <- step$text

  step_mask <- str_detect(description, detect)

  # No matching step found
  if (sum(step_mask) == 0) {
    snippet <- format_step_snippet(SNIPPET_KEYWORDS[[step$type]], description, parameters)
    snippet_lines <- strsplit(snippet, "\n")[[1]]
    abort(
      glue("No step found for: \"{description}\""),
      body = c(
        i = "Add a step definition:",
        set_names(snippet_lines, rep(" ", length(snippet_lines)))
      ),
      trace = empty_trace()
    )
  }

  # Ambiguous step
  if (sum(step_mask) > 1) {
    definitions <- steps[step_mask] |>
      map_chr(\(definition) {
        location <- srcref_location(attr(definition, "srcref"))
        location <- if (is.null(location)) "" else glue(" ({location})")
        glue("\"{attr(definition, 'description')}\"{location}")
      })
    abort(
      glue("Multiple step definitions match: \"{description}\""),
      body = c(
        i = "Make the step match only one of:",
        set_names(definitions, rep("*", length(definitions)))
      ),
      trace = empty_trace()
    )
  }

  matched_step <- steps[step_mask][[1]]

  parameter_names <- attr(patterns[step_mask][[1]], "parameters")

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
      # `{}` passes the matched text as is
      if (parameter_name == "") {
        return(value)
      }
      Find(\(x) x$name == parameter_name, parameters)$transformer(value)
    }
  )

  # Add the data table and the docstring, in the order they are written
  params <- append(params, unname(unclass(step)[step$argument_order]))

  # Name parameters according to function formals
  impl_formals <- names(formals(matched_step))
  names(params) <- impl_formals[impl_formals != "context"]

  # Enrich step with matched function and arguments
  step$matched_fn <- matched_step
  step$arguments <- params
  step$definition_location <- attr(matched_step, "srcref")

  step
}

# A step without a type, like a leading `*`, gets a Given snippet
SNIPPET_KEYWORDS <- c(Context = "Given", Action = "When", Outcome = "Then", Unknown = "Given")

#' Format a step snippet for error messages
#'
#' @keywords internal
#' @noRd
#' @importFrom stringr str_count str_replace_all
#' @importFrom glue glue
format_step_snippet <- function(keyword, description, parameters) {
  fn <- tolower(keyword)
  # {int} before {float}, which also matches integers
  ordered_names <- intersect(c("string", "int", "float"), names(parameters))
  # Escape what a Cucumber Expression would read as syntax, for the R string
  result <- str_replace_all(description, "([\\\\(){}/])", "\\\\\\\\\\1")
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
  glue('{fn}("{result}", function({arg_str}) {{\n  pending()\n}})')
}

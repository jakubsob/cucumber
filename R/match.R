#' Match steps in pickles to step definitions
#'
#' @description
#' Enriches pickle steps with matched functions and extracted arguments.
#' A step without exactly one matching definition gets the status "undefined"
#' or "ambiguous" and an error explaining it, so the run can report it.
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
    {
      patterns <- compile_steps(steps, parameters)
      pickles |>
        map(\(pickle) {
          pickle$steps <- pickle$steps |>
            map(\(step) {
              match_single_step(step, steps, parameters, patterns)
            })
          pickle
        })
    },
    purrr_error_indexed = unwrap_purrr_error
  )
}

#' Convert every step definition's expression to a regular expression
#'
#' @keywords internal
#' @noRd
#' @importFrom purrr map
compile_steps <- function(steps, parameters) {
  map(steps, \(step) expression_to_pattern(attr(step, "description"), parameters))
}

#' Mark a step that can't be run, keeping the reason as its error
#'
#' @keywords internal
#' @noRd
#' @importFrom rlang error_cnd format_error_bullets
unmatched_step <- function(step, status, message, body) {
  step$status <- status
  step$error <- error_cnd(
    class = paste0("cucumber_", status),
    message = paste(c(message, format_error_bullets(body)), collapse = "\n"),
    trace = empty_trace()
  )
  step
}

#' Match a single step to its definition
#'
#' @keywords internal
#' @noRd
#' @importFrom purrr map map_chr map_lgl
#' @importFrom stringr str_detect str_match
#' @importFrom rlang exec
#' @importFrom glue glue
match_single_step <- function(
  step,
  steps = get_steps(),
  parameters = get_parameters(),
  patterns = compile_steps(steps, parameters)
) {
  description <- step$text

  step_mask <- map_lgl(patterns, \(pattern) str_detect(description, pattern))

  # No matching step found
  if (sum(step_mask) == 0) {
    argument_names <- c(data_table = "dataTable", docstring = "docString")
    snippet <- format_step_snippet(
      SNIPPET_KEYWORDS[[step$type]],
      description,
      parameters,
      unname(argument_names[step$argument_order])
    )
    snippet_lines <- strsplit(snippet, "\n")[[1]]
    return(unmatched_step(
      step,
      "undefined",
      glue("No step found for: \"{description}\""),
      c(
        i = "Add a step definition:",
        set_names(snippet_lines, rep(" ", length(snippet_lines)))
      )
    ))
  }

  # Ambiguous step
  if (sum(step_mask) > 1) {
    definitions <- steps[step_mask] |>
      map_chr(\(definition) {
        location <- srcref_location(attr(definition, "srcref"))
        location <- if (is.null(location)) "" else glue(" ({location})")
        glue("\"{attr(definition, 'description')}\"{location}")
      })
    return(unmatched_step(
      step,
      "ambiguous",
      glue("Multiple step definitions match: \"{description}\""),
      c(
        i = "Make the step match only one of:",
        set_names(definitions, rep("*", length(definitions)))
      )
    ))
  }

  matched_step <- steps[step_mask][[1]]
  pattern <- patterns[step_mask][[1]]

  # Each top-level capture group is an argument. A parameter type's regexp
  # with capture groups of its own passes their text to its transformer.
  values <- unname(str_match(description, pattern)[1, -1])
  groups <- attr(pattern, "groups")
  impl_formals <- names(formals(matched_step))

  # Transformed when the step runs, so a failing transformer fails the step
  arguments <- function() {
    # Map, as purrr would wrap a transformer's error
    params <- Map(
      \(group, parameter) {
        children <- which(groups == group)
        exec(
          parameter$transformer,
          !!!as.list(values[if (length(children)) children else group])
        )
      },
      which(groups == 0),
      attr(pattern, "parameters")
    )

    # Add the data table and the docstring, in the order they are written
    params <- append(params, unname(unclass(step)[step$argument_order]))

    # Name parameters according to function formals
    names(params) <- impl_formals[impl_formals != "context"]
    params
  }

  # Enrich step with matched function and arguments
  step$matched_fn <- matched_step
  step$arguments <- arguments
  step$definition_location <- attr(matched_step, "srcref")

  step
}

# A step without a type, like a leading `*`, gets a Given snippet
SNIPPET_KEYWORDS <- c(Context = "Given", Action = "When", Outcome = "Then", Unknown = "Given")

#' Format a step snippet for error messages
#'
#' Like cucumber-js, each expression that matches the step is suggested, the
#' first one as code and the others commented out. Parameters are named after
#' their type, numbered when a type is used more than once: `int`, `int2`.
#'
#' @param argument_names Names of the step's data table and doc string
#'   arguments, in the order they are written.
#' @keywords internal
#' @noRd
#' @importFrom glue glue
format_step_snippet <- function(keyword, description, parameters, argument_names = character()) {
  fn <- tolower(keyword)
  definitions <- vapply(
    generate_expressions(description, parameters),
    \(generated) {
      types <- vapply(generated$parameters, \(p) p$name, character(1))
      uses <- vapply(seq_along(types), \(i) sum(types[seq_len(i)] == types[[i]]), integer(1))
      names <- ifelse(uses == 1, types, paste0(types, uses))
      args <- paste(c(names, argument_names, "context"), collapse = ", ")
      # Escape the expression for an R string
      expression <- gsub("([\\\\\"])", "\\\\\\1", generated$expression)
      glue('{fn}("{expression}", function({args}) {{')
    },
    character(1)
  )
  definitions[-1] <- paste("#", definitions[-1])
  paste(c(definitions, "  pending()", "})"), collapse = "\n")
}

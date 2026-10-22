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
    definitions <- snippet_definitions(
      SNIPPET_KEYWORDS[[step$type]],
      description,
      parameters,
      unname(STEP_ARGUMENT_NAMES[step$argument_order])
    )
    step$snippets <- paste0(definitions, "\n", SNIPPET_BODY)
    snippet_lines <- strsplit(format_step_snippet(definitions), "\n")[[1]]
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

  # The definitions that match, for the step's test step message
  step$definition_ids <- unlist(lapply(unname(steps[step_mask]), attr, "id"))
  step$match_arguments <- lapply(unname(patterns[step_mask]), \(pattern) step_match_arguments(description, pattern))

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
  impl_formals <- formals(matched_step)

  # Transformed when the step runs, so a failing transformer fails the step
  arguments <- function() {
    check_arity(
      impl_formals,
      map_chr(attr(pattern, "parameters"), "name"),
      unname(STEP_ARGUMENT_NAMES[step$argument_order])
    )
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
    step_arguments <- unclass(step)[step$argument_order]
    if (!is.null(step$docstring)) {
      step_arguments$docstring <- docstring_argument(step$docstring)
    }
    params <- append(params, unname(step_arguments))

    # Name parameters according to function formals, or pass them by position to `...`
    if (!"..." %in% names(impl_formals)) {
      names(params) <- setdiff(names(impl_formals), "context")[seq_along(params)]
    }
    params
  }

  # Enrich step with matched function and arguments
  step$matched_fn <- matched_step
  step$arguments <- arguments
  step$definition_location <- attr(matched_step, "srcref")

  step
}

#' Fail when a step definition can't take the step's arguments: its parameters,
#' data table or doc string, and `context`. A definition with `...` takes any
#' number of them, and its arguments with a default value can be left out.
#'
#' @param formals The step definition's arguments, from `formals()`
#' @param types Names of the parameter types of the step's parameters
#' @param argument_names Names of the step's data table and doc string arguments
#' @keywords internal
#' @noRd
check_arity <- function(formals, types, argument_names) {
  expected <- length(types) + length(argument_names) + 1
  # `context` is passed by name, the other arguments by position
  required <- max(0, which(vapply(formals, rlang::is_missing, logical(1))[names(formals) != "context"])) + 1
  if ("..." %in% names(formals) || (expected >= required && expected <= length(formals))) {
    return(invisible())
  }
  # A regular expression's capture group or `{}` has no type name to use
  types[make.names(types) != types] <- "arg"
  args <- paste(c(snippet_argument_names(types), argument_names, "context"), collapse = ", ")
  abort(
    glue(
      "The step definition has {length(formals)} argument{if (length(formals) == 1) '' else 's'}, ",
      "but the step passes {expected}."
    ),
    body = c(i = glue("Use `function({args})`.")),
    call = NULL,
    trace = empty_trace()
  )
}

#' A doc string as a step gets it: one string, or its lines with the
#' `cucumber.docstring_as_lines` option, with its media type in either case
#'
#' @param lines The pickle step's doc string lines
#' @keywords internal
#' @noRd
docstring_argument <- function(lines) {
  new_docstring(
    if (getOption("cucumber.docstring_as_lines", FALSE)) c(lines) else paste(lines, collapse = "\n"),
    attr(lines, "media_type")
  )
}

# Snippet names of a step's data table and doc string arguments
STEP_ARGUMENT_NAMES <- c(data_table = "data_table", docstring = "doc_string")

#' Name arguments after their parameter types, numbered when a type is used
#' more than once: `int`, `int2`
#' @keywords internal
#' @noRd
snippet_argument_names <- function(types) {
  uses <- vapply(seq_along(types), \(i) sum(types[seq_len(i)] == types[[i]]), integer(1))
  ifelse(uses == 1, types, paste0(types, uses))
}

# A step without a type, like a leading `*`, gets a Given snippet
SNIPPET_KEYWORDS <- c(Context = "Given", Action = "When", Outcome = "Then", Unknown = "Given")

#' Format a step snippet for error messages
#'
#' Each expression that matches the step is suggested, the first one as code
#' and the others commented out. Parameters are named after their type,
#' numbered when a type is used more than once: `int`, `int2`.
#'
#' @param definitions The step definitions of the snippet, from
#'   `snippet_definitions()`
#' @keywords internal
#' @noRd
format_step_snippet <- function(definitions) {
  definitions[-1] <- paste("#", definitions[-1])
  paste(c(definitions, SNIPPET_BODY), collapse = "\n")
}

SNIPPET_BODY <- "  pending()\n})"

#' The first line of a step definition for each expression that matches the
#' step, its call up to the opening brace of the function body
#'
#' @param argument_names Names of the step's data table and doc string
#'   arguments, in the order they are written.
#' @keywords internal
#' @noRd
#' @importFrom glue glue
snippet_definitions <- function(keyword, description, parameters, argument_names = character()) {
  fn <- tolower(keyword)
  vapply(
    generate_expressions(description, parameters),
    \(generated) {
      types <- vapply(generated$parameters, \(p) p$name, character(1))
      args <- paste(c(snippet_argument_names(types), argument_names, "context"), collapse = ", ")
      # Escape the expression for an R string
      expression <- gsub("([\\\\\"])", "\\\\\\1", generated$expression)
      glue('{fn}("{expression}", function({args}) {{')
    },
    character(1)
  )
}

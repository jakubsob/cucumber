#' @importFrom rlang abort exec try_fetch cnd_signal error_cnd format_error_bullets trace_back `%||%`
#' @importFrom glue glue
#' @importFrom purrr map walk partial keep flatten
#' @importFrom testthat context_start_file test_that
parse_token <- function(
  tokens,
  steps = get_steps(),
  parameters = get_parameters(),
  hooks = get_hooks(),
  tags = NULL
) {
  try_fetch(
    map(tokens, \(token) {
      switch(
        token$type,
        "Scenario" = function() {
          scenario_tags <- c(token$tags %||% character(0))
          if (!is.null(tags)) {
            result <- evaluate_tag_expression(tags, scenario_tags)
            if (!result) {
              return(invisible(NULL))
            }
          }
          test_that(glue("Scenario: {token$value}"), {
            .context <- new.env()
            calls <- parse_token(token$children, steps, parameters)
            after <- get_hook(hooks, "after")
            before <- get_hook(hooks, "before")

            on.exit(after(.context, token$value))
            before(.context, token$value)
            for (call in calls) {
              step <- unclass(call)
              description <- attr(step, "description")
              args <- attr(step, "args")
              src <- attr(step, "srcref")
              attributes(step) <- NULL
              withCallingHandlers(
                exec(step, !!!args, context = .context),
                error = function(e) {
                  if (inherits(e, "expectation")) {
                    return()
                  }
                  trace <- rlang::trace_back()
                  internal_pkgs <- c("cucumber", "rlang", "base", "methods")
                  is_internal <- vapply(
                    trace$envs,
                    function(env) {
                      environmentName(topenv(env)) %in% internal_pkgs
                    },
                    logical(1)
                  )
                  user_trace <- if (any(!is_internal)) {
                    trace[!is_internal]
                  } else {
                    NULL
                  }
                  location <- if (!is.null(src)) {
                    glue(
                      "{getSrcFilename(src)}:",
                      "{getSrcLocation(src, 'line', first = TRUE)}"
                    )
                  }
                  cnd <- rlang::error_cnd(
                    message = rlang::format_error_bullets(c(
                      glue("Step \"{description}\" failed"),
                      if (!is.null(location)) {
                        c(i = glue("Defined at: {location}"))
                      }
                    )),
                    parent = e,
                    call = NULL,
                    trace = user_trace
                  )
                  stop(cnd)
                }
              )
            }
          })
        },
        "Scenario Outline" = function() {
          # Expand scenario outline first, then filter by tags
          scenarios <- expand_scenario_outline(token)
          for (i in seq_along(scenarios)) {
            scenario <- scenarios[[i]]
            # Check tags for each expanded scenario
            scenario_tags <- scenario$tags %||% character(0)
            if (is.null(tags) || evaluate_tag_expression(tags, scenario_tags)) {
              # Parse and execute the scenario
              call <- parse_token(list(scenario), steps, parameters, hooks)[[1]]
              exec(call)
            }
          }
        },
        "Feature" = function(file_name = token$value) {
          context_start_file(glue("Feature: {file_name}"))

          feature_tags <- token$tags %||% character(0)
          # Propagate feature tags to child scenarios
          children <- token$children |>
            map(\(child) {
              if (child$type %in% c("Scenario", "Scenario Outline")) {
                child$tags <- unique(c(
                  feature_tags,
                  child$tags %||% character(0)
                ))
              }
              child
            })
          # Append Background steps before each Scenario steps
          if (children[[1]]$type == "Background") {
            background <- children[[1]]
            children <- children[2:length(children)] |>
              map(\(x) {
                x$children <- c(background$children, x$children)
                x
              })
          }

          calls <- parse_token(children, steps, parameters, hooks, tags)
          for (call in calls) {
            exec(call)
          }
        },
        "Step" = parse_step(token, steps, parameters),
        abort(glue("Unknown token type: {token$type}"))
      )
    }),
    purrr_error_indexed = function(err) cnd_signal(err$parent)
  )
}

#' @importFrom stringr str_count str_replace_all
format_step_snippet <- function(description, parameters) {
  ordered_names <- intersect(c("string", "float", "int"), names(parameters))
  result <- description
  params_found <- character(0)
  for (type_name in ordered_names) {
    param <- parameters[[type_name]]
    n <- str_count(result, param$regexp)
    if (n > 0) {
      params_found <- c(params_found, rep(type_name, n))
      result <- str_replace_all(result, param$regexp, paste0("{", type_name, "}"))
    }
  }
  type_totals <- table(params_found)
  type_seen <- list()
  args <- character(length(params_found))
  for (i in seq_along(params_found)) {
    t <- params_found[[i]]
    type_seen[[t]] <- (type_seen[[t]] %||% 0L) + 1L
    args[[i]] <- if (as.integer(type_totals[[t]]) > 1L) paste0(t, "_", type_seen[[t]]) else t
  }
  arg_str <- paste(c(args, "context"), collapse = ", ")
  glue('given("{result}", function({arg_str}) {{\n  pending()\n}})')
}

#' @importFrom purrr map_chr map map_int map2 keep pluck partial
#' @importFrom stringr str_detect str_match_all
#' @importFrom rlang exec
#' @importFrom glue glue
parse_step <- function(token, steps = get_steps(), parameters = get_parameters()) {
  # Pattern to detect the step
  detect <- steps |>
    map_chr(attr, "detect") |>
    map_chr(expression_to_pattern, parameters = parameters)

  description <- token$value

  step_mask <- str_detect(description, detect)
  if (sum(step_mask) == 0) {
    snippet <- format_step_snippet(description, parameters)
    abort(
      glue("No step found for: \"{description}\""),
      body = c(i = "Add a step definition:", " " = snippet)
    )
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
  attr(step, "args") <- params
  step
}

#' @importFrom purrr keep map
expand_scenario_outline <- function(outline_token) {
  # Get all Examples sections
  examples_sections <- outline_token$children |>
    keep(~ .x$type == "Scenarios")
  # Get step templates
  steps_tokens <- outline_token$children |>
    keep(~ .x$type != "Scenarios")

  # Process each Examples section separately
  all_scenarios <- map(examples_sections, function(examples) {
    table_data <- parse_table(examples$data)
    examples_tags <- examples$tags %||% character(0)
    map(seq_len(nrow(table_data)), function(i) {
      row_data <- table_data[i, ]
      processed_steps <- steps_tokens |>
        map(\(step) {
          new_step <- step
          for (col in names(row_data)) {
            placeholder <- glue("<{col}>")
            new_step$value <- gsub(
              placeholder,
              as.character(row_data[[col]]),
              new_step$value,
              fixed = TRUE
            )
          }
          new_step
        })

      list(
        type = "Scenario",
        value = glue("{outline_token$value} (Example {i})"),
        children = processed_steps,
        tags = unique(c(outline_token$tags %||% character(0), examples_tags)),
        data = NULL
      )
    })
  })

  # Flatten the list of lists
  unlist(all_scenarios, recursive = FALSE)
}

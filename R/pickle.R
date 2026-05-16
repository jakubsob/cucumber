#' Create a pickle step object
#'
#' @param keyword Step keyword (normalized to "Step")
#' @param text Step text
#' @param data_table Data table (tibble or NULL)
#' @param docstring Docstring (character or NULL)
#' @param status Execution status (NULL, "passed", "failed", "skipped", "pending")
#' @param error Error object if failed
#' @param duration Execution time in seconds
#' @param matched_fn Matched step function (added in matching phase)
#' @param arguments Named list of arguments (added in matching phase)
#' @param definition_location Source reference for error reporting
#' @return A pickle_step object
#' @keywords internal
#' @noRd
#' @importFrom rlang abort
#' @importFrom glue glue
new_pickle_step <- function(
  keyword,
  text,
  data_table = NULL,
  docstring = NULL,
  status = NULL,
  error = NULL,
  duration = NULL,
  matched_fn = NULL,
  arguments = NULL,
  definition_location = NULL
) {
  structure(
    list(
      keyword = keyword,
      text = text,
      data_table = data_table,
      docstring = docstring,
      status = status,
      error = error,
      duration = duration,
      matched_fn = matched_fn,
      arguments = arguments,
      definition_location = definition_location
    ),
    class = "pickle_step"
  )
}

#' Create a pickle object
#'
#' @param id Unique identifier
#' @param name Scenario name
#' @param tags Character vector of tags
#' @param steps List of pickle_step objects
#' @param source_line Line number in feature file
#' @return A pickle object
#' @keywords internal
#' @noRd
new_pickle <- function(
  id,
  name,
  tags = character(),
  steps = list(),
  source_line = NA_integer_
) {
  structure(
    list(
      id = id,
      name = name,
      tags = tags,
      steps = steps,
      source_line = source_line
    ),
    class = "pickle"
  )
}

#' @export
print.pickle_step <- function(x, indent = 0, ...) {
  prefix <- strrep("  ", indent)
  status_str <- if (!is.null(x$status)) {
    paste0(" [", x$status, "]")
  } else {
    ""
  }

  cat(prefix, x$keyword, " ", x$text, status_str, "\n", sep = "")

  if (!is.null(x$data_table)) {
    cat(prefix, "  <data table>\n", sep = "")
  }

  if (!is.null(x$docstring)) {
    cat(prefix, "  <docstring>\n", sep = "")
  }

  invisible(x)
}

#' @export
print.pickle <- function(x, ...) {
  tags_str <- if (length(x$tags) > 0) {
    paste0("  [", paste(paste0("@", x$tags), collapse = " "), "]")
  } else {
    ""
  }

  cat("Pickle: ", x$name, tags_str, "\n", sep = "")
  cat("  ID: ", x$id, "\n", sep = "")

  if (length(x$steps) > 0) {
    cat("  Steps:\n")
    for (step in x$steps) {
      print(step, indent = 2)
    }
  }

  invisible(x)
}

#' Create pickles from tokens
#'
#' @description
#' Converts a token tree into a list of pickle objects. This includes:
#' - Expanding scenario outlines into individual scenarios
#' - Flattening background steps into each scenario
#' - Propagating tags from feature and scenario levels
#'
#' @param tokens Token tree from tokenize()
#' @return List of pickle objects
#' @keywords internal
#' @noRd
#' @importFrom purrr map keep flatten
#' @importFrom glue glue
create_pickles <- function(tokens, feature_file = NULL) {
  # Should have exactly one Feature token at top level
  if (length(tokens) != 1 || tokens[[1]]$type != "Feature") {
    abort("Expected exactly one Feature token")
  }

  feature <- tokens[[1]]
  feature_tags <- feature$tags

  # Extract background steps if present
  background_steps <- list()
  children <- feature$children

  if (length(children) > 0 && children[[1]]$type == "Background") {
    background_steps <- children[[1]]$children
    children <- children[-1]
  }

  # Process each scenario/outline
  pickles <- children |>
    map(\(child) {
      if (child$type == "Scenario") {
        tryCatch({
          list(create_pickle_from_scenario(
            child,
            feature_tags,
            background_steps
          ))
        }, error = function(e) {
          message("Error in create_pickle_from_scenario: ", conditionMessage(e))
          stop(e)
        })
      } else if (child$type == "Scenario Outline") {
        tryCatch({
          expand_scenario_outline_to_pickles(
            child,
            feature_tags,
            background_steps
          )
        }, error = function(e) {
          message("Error in expand_scenario_outline_to_pickles: ", conditionMessage(e))
          stop(e)
        })
      } else {
        NULL
      }
    }) |>
    keep(\(x) !is.null(x)) |>
    flatten()

  if (!is.null(feature_file)) {
    pickles <- purrr::map(pickles, \(p) { p$feature_file <- feature_file; p })
  }

  pickles
}

#' Create a pickle from a scenario token
#'
#' @keywords internal
#' @noRd
create_pickle_from_scenario <- function(
  scenario_token,
  feature_tags,
  background_steps
) {
  all_tags <- unique(c(feature_tags, scenario_token$tags))

  # Convert background and scenario steps to pickle_steps
  all_step_tokens <- c(background_steps, scenario_token$children)

  steps <- all_step_tokens |>
    map(\(step_token) {
      new_pickle_step(
        keyword = step_token$type,
        text = step_token$value,
        data_table = if (!is.null(step_token$data)) {
          if (detect_table(step_token$data)) {
            parse_table(step_token$data)
          } else {
            NULL
          }
        } else {
          NULL
        },
        docstring = if (!is.null(step_token$data)) {
          if (detect_docstring(step_token$data)) {
            parse_docstring(step_token$data)
          } else {
            NULL
          }
        } else {
          NULL
        }
      )
    })

  new_pickle(
    id = generate_pickle_id(),
    name = scenario_token$value,
    tags = all_tags,
    steps = steps
  )
}

#' Expand scenario outline to pickles
#'
#' @keywords internal
#' @noRd
#' @importFrom purrr map flatten
expand_scenario_outline_to_pickles <- function(
  outline_token,
  feature_tags,
  background_steps
) {
  # Get all Examples sections
  examples_sections <- outline_token$children |>
    keep(\(x) x$type == "Scenarios")

  # Get step templates
  step_templates <- outline_token$children |>
    keep(\(x) x$type != "Scenarios")

  # Process each Examples section
  all_pickles <- examples_sections |>
    map(\(examples) {
      table_data <- parse_table(examples$data)
      examples_tags <- examples$tags

      map(seq_len(nrow(table_data)), \(i) {
        row_data <- table_data[i, ]

        # Substitute placeholders in step templates
        processed_steps <- step_templates |>
          map(\(step) {
            new_text <- step$value
            for (col in names(row_data)) {
              placeholder <- glue("<{col}>")
              new_text <- gsub(
                placeholder,
                as.character(row_data[[col]]),
                new_text,
                fixed = TRUE
              )
            }

            # Create new step token with substituted text
            new_token(
              type = step$type,
              value = new_text,
              tags = step$tags,
              children = step$children,
              data = step$data
            )
          })

        # Create pickle from processed steps
        all_tags <- unique(c(
          feature_tags,
          outline_token$tags,
          examples_tags
        ))

        # Convert background and processed steps to pickle_steps
        all_step_tokens <- c(background_steps, processed_steps)

        steps <- all_step_tokens |>
          map(\(step_token) {
            new_pickle_step(
              keyword = step_token$type,
              text = step_token$value,
              data_table = if (!is.null(step_token$data)) {
                if (detect_table(step_token$data)) {
                  parse_table(step_token$data)
                } else {
                  NULL
                }
              } else {
                NULL
              },
              docstring = if (!is.null(step_token$data)) {
                if (detect_docstring(step_token$data)) {
                  parse_docstring(step_token$data)
                } else {
                  NULL
                }
              } else {
                NULL
              }
            )
          })

        new_pickle(
          id = generate_pickle_id(),
          name = glue("{outline_token$value} (Example {i})"),
          tags = all_tags,
          steps = steps
        )
      })
    }) |>
    flatten()

  all_pickles
}

#' Generate a unique pickle ID
#'
#' @keywords internal
#' @noRd
generate_pickle_id <- function() {
  paste0("pickle-", as.character(as.numeric(Sys.time()) * 1000000))
}

#' Filter pickles by tag expression
#'
#' @param pickles List of pickle objects
#' @param tags Tag expression string (e.g., "@smoke and not @slow")
#' @return Filtered list of pickle objects
#' @keywords internal
#' @noRd
filter_pickles_by_tags <- function(pickles, tags) {
  if (is.null(tags)) {
    return(pickles)
  }

  pickles |>
    keep(\(pickle) {
      evaluate_tag_expression(tags, pickle$tags)
    })
}

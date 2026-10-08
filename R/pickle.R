#' Create a pickle step object
#'
#' @param keyword Step keyword as written ("Given", "And", "*", ...)
#' @param type Step type ("Context", "Action", "Outcome" or "Unknown"), And/But
#'   take the type of the previous step
#' @param text Step text
#' @param data_table Data table (tibble or NULL)
#' @param docstring Docstring (character or NULL)
#' @param argument_order Names of the step arguments ("docstring",
#'   "data_table") in the order they are written
#' @param status Execution status (NULL, "passed", "failed", "skipped", "pending")
#' @param error Error object if failed
#' @param duration Execution time in seconds
#' @param matched_fn Matched step function (added in matching phase)
#' @param arguments Function returning the named list of arguments (added in
#'   matching phase)
#' @param definition_location Source reference for error reporting
#' @return A pickle_step object
#' @keywords internal
#' @noRd
#' @importFrom rlang abort
#' @importFrom glue glue
new_pickle_step <- function(
  keyword,
  text,
  type = "Unknown",
  data_table = NULL,
  docstring = NULL,
  argument_order = character(),
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
      type = type,
      text = text,
      data_table = data_table,
      docstring = docstring,
      argument_order = argument_order,
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
      tags = sub("^@", "", tags),
      steps = steps,
      source_line = source_line
    ),
    class = "pickle"
  )
}

#' Compile pickles from a Gherkin document
#'
#' @description
#' A port of the official pickle compiler. It:
#' - Expands scenario outlines into one pickle per Examples row
#' - Adds the Feature's and the Rule's Background steps to each scenario that has steps
#' - Inherits tags from the Feature, the Rule, the scenario and the Examples
#'
#' @param document A document from `parse_gherkin()`
#' @return List of pickle objects
#' @keywords internal
#' @noRd
#' @importFrom purrr map flatten
create_pickles <- function(document, feature_file = NULL) {
  feature <- document$feature
  if (is.null(feature)) {
    return(list())
  }

  background <- feature$background$steps
  rules <- feature$rules |>
    map(\(rule) {
      compile_scenarios(
        rule$scenarios,
        c(feature$tags, rule$tags),
        c(background, rule$background$steps)
      )
    })
  pickles <- c(
    compile_scenarios(feature$scenarios, feature$tags, background),
    flatten(rules)
  )

  if (!is.null(feature_file)) {
    pickles <- map(pickles, \(p) {
      p$feature_file <- feature_file
      p
    })
  }

  pickles
}

#' @keywords internal
#' @noRd
#' @importFrom purrr map flatten keep
compile_scenarios <- function(scenarios, tags, background) {
  scenarios |>
    map(\(scenario) {
      if (length(scenario$examples) == 0) {
        return(list(new_pickle(
          id = generate_pickle_id(),
          name = scenario$name,
          tags = c(tags, scenario$tags),
          steps = pickle_steps(background, scenario$steps),
          source_line = scenario$line
        )))
      }
      # An outline gives a pickle for each row of each Examples with a table
      scenario$examples |>
        keep(\(examples) !is.null(examples$header)) |>
        map(\(examples) {
          map(examples$body, \(row) {
            header <- examples$header$cells
            new_pickle(
              id = generate_pickle_id(),
              name = interpolate(scenario$name, header, row$cells),
              tags = c(tags, scenario$tags, examples$tags),
              steps = pickle_steps(background, scenario$steps, header, row$cells),
              source_line = row$line
            )
          })
        }) |>
        flatten()
    }) |>
    flatten()
}

#' Background steps run only before a scenario with steps, and outline
#' placeholders are replaced only in the scenario's own steps.
#' And/But take the type of the previous step.
#' @keywords internal
#' @noRd
#' @importFrom purrr map2
#' @importFrom stringr str_trim
pickle_steps <- function(background, steps, header = character(), values = character()) {
  if (length(steps) == 0) {
    return(list())
  }
  in_scenario <- rep(c(FALSE, TRUE), c(length(background), length(steps)))
  type <- "Unknown"
  map2(c(background, steps), in_scenario, \(step, in_scenario) {
    fill <- if (in_scenario) \(x) interpolate(x, header, values) else identity
    if (step$keyword_type != "Conjunction") {
      type <<- step$keyword_type
    }
    arguments <- c(docstring = step$docstring$line, data_table = step$data_table$line)
    new_pickle_step(
      keyword = str_trim(step$keyword),
      type = type,
      text = fill(step$text),
      data_table = if (!is.null(step$data_table)) {
        parse_table(map(step$data_table$rows, \(row) fill(row$cells)))
      },
      docstring = if (!is.null(step$docstring)) fill(step$docstring$content),
      argument_order = as.character(names(sort(arguments)))
    )
  })
}

#' Replace `<name>` placeholders with the values of an Examples row
#' @keywords internal
#' @noRd
interpolate <- function(x, header, values) {
  for (i in seq_along(header)) {
    x <- gsub(paste0("<", header[[i]], ">"), values[[i]], x, fixed = TRUE)
  }
  x
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

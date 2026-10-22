#' Create a pickle step object
#'
#' @param keyword Step keyword as written ("Given", "And", "*", ...)
#' @param type Step type ("Context", "Action", "Outcome" or "Unknown"), And/But
#'   take the type of the previous step
#' @param text Step text
#' @param line Line of the step in the feature file
#' @param data_table Data table (tibble or NULL)
#' @param docstring Docstring lines (character or NULL), with its media type in
#'   the `media_type` attribute
#' @param argument_order Names of the step arguments ("docstring",
#'   "data_table") in the order they are written
#' @param status Execution status (NULL, "passed", "failed", "skipped", "pending")
#' @param error Error object if failed
#' @param duration Execution time in seconds
#' @param matched_fn Matched step function (added in matching phase)
#' @param arguments Function returning the named list of arguments (added in
#'   matching phase)
#' @param definition_location Source reference for error reporting
#' @param id Id of the step's PickleStep message
#' @param message The PickleStep message
#' @return A pickle_step object
#' @keywords internal
#' @noRd
#' @importFrom rlang abort
#' @importFrom glue glue
new_pickle_step <- function(
  keyword,
  text,
  type = "Unknown",
  line = NULL,
  data_table = NULL,
  docstring = NULL,
  argument_order = character(),
  status = NULL,
  error = NULL,
  duration = NULL,
  matched_fn = NULL,
  arguments = NULL,
  definition_location = NULL,
  id = NULL,
  message = NULL
) {
  structure(
    list(
      keyword = keyword,
      type = type,
      text = text,
      line = line,
      data_table = data_table,
      docstring = docstring,
      argument_order = argument_order,
      status = status,
      error = error,
      duration = duration,
      matched_fn = matched_fn,
      arguments = arguments,
      definition_location = definition_location,
      id = id,
      message = message
    ),
    class = "pickle_step"
  )
}

#' Create a docstring: its text with its media type in the `media_type`
#' attribute, left out when the docstring has none
#'
#' @param content Docstring text, its lines or one string
#' @param media_type Media type, like "json" (character or NULL)
#' @return A character vector
#' @keywords internal
#' @noRd
new_docstring <- function(content, media_type = NULL) {
  structure(content, media_type = media_type)
}

#' Create a pickle object
#'
#' @param name Scenario name
#' @param tags Character vector of tags
#' @param steps List of pickle_step objects
#' @param source_line Line number in feature file
#' @param lines Lines that select the pickle when running `file:line`: the
#'   scenario's line, and for an outline row also the row's line
#' @param message The Pickle message
#' @return A pickle object
#' @keywords internal
#' @noRd
new_pickle <- function(
  name,
  tags = character(),
  steps = list(),
  source_line = NA_integer_,
  lines = source_line,
  message = NULL
) {
  structure(
    list(
      name = name,
      tags = sub("^@", "", tags),
      steps = steps,
      source_line = source_line,
      lines = lines,
      message = message
    ),
    class = "pickle"
  )
}

#' Compile pickles from a Gherkin document
#'
#' @description
#' A port of the official pickle compiler, pickles/compile.ts. It:
#' - Expands scenario outlines into one pickle per Examples row
#' - Adds the Feature's and the Rule's Background steps to each scenario that has steps
#' - Inherits tags from the Feature, the Rule, the scenario and the Examples
#'
#' Each pickle keeps its Pickle message, with ids from `new_id()` assigned in
#' the official order.
#'
#' @param document A document from `parse_gherkin()`
#' @param feature_file The uri of the pickles, the document's by default
#' @return List of pickle objects
#' @keywords internal
#' @noRd
create_pickles <- function(document, feature_file = NULL) {
  feature <- document$feature
  if (is.null(feature)) {
    return(list())
  }
  compile <- function(tags, background, scenario) {
    compile_scenario(tags, background, scenario, feature$language, feature_file %||% document$uri)
  }

  pickles <- list()
  background <- list()
  for (child in feature$children) {
    if (!is.null(child$background)) {
      background <- child$background$steps
    } else if (!is.null(child$rule)) {
      rule <- child$rule
      rule_background <- background
      for (rule_child in rule$children) {
        if (!is.null(rule_child$background)) {
          rule_background <- c(rule_background, rule_child$background$steps)
        } else {
          pickles <- c(pickles, compile(c(feature$tags, rule$tags), rule_background, rule_child$scenario))
        }
      }
    } else {
      pickles <- c(pickles, compile(feature$tags, background, child$scenario))
    }
  }

  if (!is.null(feature_file)) {
    pickles <- map(pickles, \(p) {
      p$feature_file <- feature_file
      p
    })
  }

  pickles
}

#' A scenario's pickle, or for an outline a pickle for each row of each
#' Examples with a table
#' @keywords internal
#' @noRd
#' @importFrom purrr map keep flatten
compile_scenario <- function(tags, background, scenario, language, uri) {
  pickle <- function(steps, tags, row = NULL) {
    # The steps get their ids before the pickle
    force(steps)
    header <- examples_header(row)
    name <- interpolate(scenario$name, header, map_chr(row$row$cells, "value"))
    message <- drop_null(list(
      id = new_id(),
      uri = uri,
      location = row$row$location %||% scenario$location,
      astNodeIds = as.list(c(scenario$id, row$row$id)),
      tags = map(tags, \(tag) list(name = tag$name, astNodeId = tag$id)),
      name = name,
      language = language,
      steps = map(steps, "message")
    ))
    new_pickle(
      name = name,
      tags = map_chr(tags, "name"),
      steps = steps,
      source_line = message$location$line,
      lines = unique(c(scenario$location$line, row$row$location$line)),
      message = message
    )
  }

  if (length(scenario$examples) == 0) {
    return(list(pickle(pickle_steps(background, scenario$steps), c(tags, scenario$tags))))
  }
  scenario$examples |>
    keep(\(examples) !is.null(examples$tableHeader)) |>
    map(\(examples) {
      map(examples$tableBody, \(row) {
        row <- list(row = row, header = examples$tableHeader)
        steps <- pickle_steps(background, scenario$steps, row)
        pickle(steps, c(tags, scenario$tags, examples$tags), row)
      })
    }) |>
    flatten()
}

examples_header <- function(row) {
  map_chr(row$header$cells, "value")
}

#' Background steps run only before a scenario with steps, and outline
#' placeholders are replaced only in the scenario's own steps.
#' And/But take the type of the previous step.
#'
#' @param row An Examples row, with the `row` and the `header` of its table
#' @keywords internal
#' @noRd
#' @importFrom purrr map map2 map_chr
#' @importFrom stringr str_trim
pickle_steps <- function(background, steps, row = NULL) {
  if (length(steps) == 0) {
    return(list())
  }
  header <- examples_header(row)
  values <- map_chr(row$row$cells, "value")
  in_scenario <- rep(c(FALSE, TRUE), c(length(background), length(steps)))
  type <- "Unknown"
  map2(c(background, steps), in_scenario, \(step, in_scenario) {
    fill <- if (in_scenario) \(x) interpolate(x, header, values) else identity
    if (step$keywordType != "Conjunction") {
      type <<- step$keywordType
    }
    table <- step$dataTable
    docstring <- step$docString
    arguments <- c(docstring = docstring$location$line, data_table = table$location$line)
    argument_order <- as.character(names(sort(arguments)))
    # The index of an argument, when a step has both
    index <- function(name) if (length(arguments) > 1) match(name, argument_order)
    rows <- map(table$rows, \(row) fill(map_chr(row$cells, "value")))
    media_type <- if (!is.null(docstring$mediaType)) fill(docstring$mediaType)
    content <- if (!is.null(docstring)) fill(docstring$content)

    argument <- drop_null(list(
      docString = if (!is.null(docstring)) {
        drop_null(list(argumentIndex = index("docstring"), content = content, mediaType = media_type))
      },
      dataTable = if (!is.null(table)) {
        drop_null(list(
          argumentIndex = index("data_table"),
          rows = map(rows, \(cells) list(cells = map(cells, \(value) list(value = value))))
        ))
      }
    ))
    message <- drop_null(list(
      id = new_id(),
      text = fill(step$text),
      type = type,
      argument = if (length(argument) > 0) argument,
      astNodeIds = as.list(c(step$id, if (in_scenario) row$row$id))
    ))
    new_pickle_step(
      keyword = str_trim(step$keyword),
      type = type,
      text = message$text,
      line = step$location$line,
      data_table = if (!is.null(table)) parse_table(rows),
      docstring = if (!is.null(docstring)) new_docstring(docstring_lines(content), media_type),
      argument_order = argument_order,
      id = message$id,
      message = message
    )
  })
}

#' The lines of a doc string's content
#' @keywords internal
#' @noRd
docstring_lines <- function(content) {
  if (content == "") character() else strsplit(paste0(content, "\n"), "\n", fixed = TRUE)[[1]]
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

#' Keep the pickles selected by `tags`, `name` and `lines`, see `test()`
#' @keywords internal
#' @noRd
filter_pickles <- function(pickles, tags = NULL, name = NULL, lines = integer()) {
  pickles |>
    filter_pickles_by_tags(tags) |>
    filter_pickles_by_name(name) |>
    filter_pickles_by_lines(lines)
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

#' Keep pickles whose name matches any of the regular expressions in `name`
#' @keywords internal
#' @noRd
filter_pickles_by_name <- function(pickles, name) {
  if (is.null(name)) {
    return(pickles)
  }
  keep(pickles, \(pickle) any(vapply(name, grepl, logical(1), x = pickle$name)))
}

#' Keep pickles selected by any of the `lines` of their feature file
#' @keywords internal
#' @noRd
filter_pickles_by_lines <- function(pickles, lines) {
  if (length(lines) == 0) {
    return(pickles)
  }
  keep(pickles, \(pickle) any(pickle$lines %in% lines))
}

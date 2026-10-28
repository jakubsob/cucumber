# Cucumber Messages (https://github.com/cucumber/messages): the protocol
# official Cucumber implementations report a run with, written as NDJSON by
# CucumberMessagesReporter. Messages are lists with the fields of the official
# schema, and arrays are lists, so they keep their shape in JSON.

PROTOCOL_VERSION <- "34.2.1"

#' Ids of messages, incrementing like the official IdGenerator.incrementing,
#' from 0 at the start of each run
#' @noRd
ids <- new.env(parent = emptyenv())
ids$next_id <- 0L
ids$registered <- 0L

new_id <- function() {
  id <- ids$next_id
  ids$next_id <- id + 1L
  as.character(id)
}

#' Number ids from 0 until `frame` ends. A run nested in another one, like in a
#' step that tests cucumber, has ids of its own, and the outer run's ids
#' continue after it.
#' @noRd
local_ids <- function(frame = parent.frame()) {
  outer <- ids$next_id
  ids$next_id <- 0L
  withr::defer(ids$next_id <- outer, frame)
}

#' Step definitions, hooks and parameter types are reported in the order they
#' are defined
#' @noRd
next_registration <- function() {
  ids$registered <- ids$registered + 1L
  ids$registered
}

#' Send a message to the reporter
#' @param type The message's type, like "testCaseStarted"
#' @noRd
emit <- function(reporter, type, message) {
  cucumber_event(reporter, "add_message", set_names(list(message), type))
  invisible(message)
}

#' An envelope as one line of NDJSON
#' @noRd
envelope_json <- function(envelope) {
  rlang::check_installed("jsonlite", "to write Cucumber Messages.")
  as.character(jsonlite::toJSON(envelope, auto_unbox = TRUE, digits = NA))
}

timestamp <- function(time = Sys.time()) {
  seconds_and_nanos(as.numeric(time))
}

duration <- function(seconds) {
  seconds_and_nanos(seconds %||% 0)
}

seconds_and_nanos <- function(x) {
  seconds <- floor(x)
  list(seconds = seconds, nanos = round((x - seconds) * 1e9))
}

seconds_since <- function(start) {
  as.numeric(difftime(Sys.time(), start, units = "secs"))
}

#' An empty object, `{}` in JSON
#' @noRd
empty_object <- function() {
  set_names(list(), character())
}

# Sources -----------------------------------------------------------------

meta_message <- function() {
  sys <- Sys.info()
  list(
    protocolVersion = PROTOCOL_VERSION,
    implementation = list(name = "cucumber-r", version = as.character(utils::packageVersion("cucumber"))),
    runtime = list(name = "R", version = paste(R.version$major, R.version$minor, sep = ".")),
    os = list(name = tolower(sys[["sysname"]]), version = sys[["release"]]),
    cpu = list(name = R.version$arch)
  )
}

#' The Source message of a feature file: its text as it is in the file
#' @noRd
source_message <- function(path) {
  data <- readChar(path, file.size(path), useBytes = TRUE)
  Encoding(data) <- "UTF-8"
  list(uri = path, data = data, mediaType = gherkin_flavour(path)$media_type)
}

#' A parse error, with its location read from the error message
#' @noRd
parse_error_message <- function(uri, error) {
  location <- as.integer(regmatches(error, regexec("^\\((\\d+):(\\d+)\\)", error))[[1]][-1])
  list(
    source = list(uri = uri, location = drop_null(list(
      line = location[1],
      column = if (location[2] > 0) location[2]
    ))),
    message = error
  )
}

# Glue --------------------------------------------------------------------

#' Give the step definitions, hooks and parameter types their ids and report
#' them, in the order they are defined. Built-in parameter types aren't
#' reported.
#'
#' A step definition whose expression uses an undefined
#' parameter type is reported as an undefinedParameterType and left out, so
#' its steps are undefined.
#'
#' @return The steps and hooks, each with its `id`
#' @noRd
#' @importFrom purrr map map_dbl
emit_glue <- function(reporter, steps, hooks, parameters) {
  undefined <- integer()
  defined <- Filter(\(parameter) !isTRUE(parameter$builtin), parameters)
  glue <- c(
    map(defined, \(parameter) list(kind = "parameter", order = parameter$order, item = parameter)),
    map(seq_along(steps), \(i) list(kind = "step", order = attr(steps[[i]], "order"), index = i)),
    map(seq_along(hooks), \(i) list(kind = "hook", order = hooks[[i]]$order, index = i))
  )
  order <- map_dbl(glue, \(item) item$order)
  for (item in glue[order(order)]) {
    id <- new_id()
    if (item$kind == "parameter") {
      emit(reporter, "parameterType", parameter_type_message(id, item$item))
    } else if (item$kind == "step") {
      expression <- attr(steps[[item$index]], "description")
      type <- undefined_parameter_type(expression, parameters)
      if (!is.null(type)) {
        undefined <- c(undefined, item$index)
        emit(reporter, "undefinedParameterType", list(name = type, expression = expression))
        next
      }
      attr(steps[[item$index]], "id") <- id
      emit(reporter, "stepDefinition", step_definition_message(id, steps[[item$index]]))
    } else {
      hooks[[item$index]]$id <- id
      emit(reporter, "hook", hook_message(id, hooks[[item$index]]))
    }
  }
  if (length(undefined) > 0) steps <- .steps(!!!steps[-undefined])
  list(steps = steps, hooks = hooks)
}

#' The name of the undefined parameter type an expression uses, or NULL. Other
#' problems of the expression are reported when steps are matched with it.
#' @noRd
undefined_parameter_type <- function(expression, parameters) {
  tryCatch(
    {
      expression_to_pattern(expression, parameters)
      NULL
    },
    cucumber_undefined_parameter_type = \(e) e$parameter_type,
    cucumber_expression_error = \(e) NULL
  )
}

source_reference <- function(srcref) {
  file <- if (!is.null(srcref)) utils::getSrcFilename(srcref, full.names = TRUE)
  if (length(file) == 0) {
    return(empty_object())
  }
  # Like the uri of a feature file, without the `./` of a file sourced from the run's directory
  list(uri = as.character(fs::path_norm(file)), location = list(line = utils::getSrcLocation(srcref, "line")))
}

step_definition_message <- function(id, step) {
  expression <- attr(step, "description")
  regex <- is_regular_expression(expression)
  list(
    id = id,
    pattern = list(
      source = if (grepl("^/.*/$", expression)) substr(expression, 2, nchar(expression) - 1) else expression,
      type = if (regex) "REGULAR_EXPRESSION" else "CUCUMBER_EXPRESSION"
    ),
    sourceReference = source_reference(attr(step, "srcref"))
  )
}

HOOK_TYPES <- c(
  before_all = "BEFORE_TEST_RUN",
  after_all = "AFTER_TEST_RUN",
  before = "BEFORE_TEST_CASE",
  after = "AFTER_TEST_CASE",
  before_step = "BEFORE_TEST_STEP",
  after_step = "AFTER_TEST_STEP"
)

hook_message <- function(id, hook) {
  drop_null(list(
    id = id,
    type = HOOK_TYPES[[hook$name]],
    name = hook$hook_name,
    tagExpression = hook$tags,
    sourceReference = source_reference(hook$srcref)
  ))
}

parameter_type_message <- function(id, parameter) {
  srcref <- attr(parameter$transformer, "srcref")
  drop_null(list(
    id = id,
    name = parameter$name,
    regularExpressions = as.list(parameter$regexp),
    preferForRegularExpressionMatch = parameter$prefer_for_regexp_match,
    useForSnippets = parameter$use_for_snippets,
    sourceReference = if (!is.null(srcref)) source_reference(srcref)
  ))
}

#' The arguments a step definition's pattern matches in a step's text: for
#' each top-level capture group, its start and value and its nested groups.
#' A group that didn't match has neither.
#' @noRd
#' @importFrom purrr map map2
step_match_arguments <- function(text, pattern) {
  location <- stringi::stri_locate_first_regex(text, pattern, capture_groups = TRUE)
  groups <- attr(location, "capture_groups")
  parents <- attr(pattern, "groups")
  group <- function(i) {
    start <- groups[[i]][1, "start"]
    end <- groups[[i]][1, "end"]
    children <- which(parents == i)
    out <- drop_null(list(
      children = if (length(children) > 0) map(children, group),
      start = if (!is.na(start)) start - 1L,
      value = if (!is.na(start)) substr(text, start, end)
    ))
    if (length(out) == 0) empty_object() else out
  }
  arguments <- map2(which(parents == 0), attr(pattern, "parameters"), \(i, parameter) {
    drop_null(list(
      group = group(i),
      parameterTypeName = if (nzchar(parameter$name)) parameter$name
    ))
  })
  list(stepMatchArguments = arguments)
}

# Test cases --------------------------------------------------------------

#' Plan a pickle's test case: its before hooks, its steps and its after hooks,
#' each with the id of its test step
#'
#' @return The pickle with its `test_case`, and its steps with their
#'   `test_step_id`
#' @noRd
#' @importFrom purrr map
new_test_case <- function(pickle, hooks) {
  hook_steps <- function(kind) {
    map(get_hooks_to_run(hooks, kind, pickle$tags), \(hook) list(id = new_id(), hook = hook))
  }
  id <- new_id()
  before <- hook_steps("before")
  pickle$steps <- map(pickle$steps, \(step) {
    step$test_step_id <- new_id()
    step
  })
  after <- hook_steps("after")
  pickle$test_case <- list(id = id, before = before, after = after)
  pickle
}

test_case_message <- function(pickle, test_run_started_id = NULL) {
  hook_step <- \(step) drop_null(list(id = step$id, hookId = step$hook$id))
  pickle_step <- \(step) {
    list(
      id = step$test_step_id,
      pickleStepId = step$id,
      stepDefinitionIds = as.list(step$definition_ids),
      stepMatchArgumentsLists = step$match_arguments %||% list()
    )
  }
  test_case <- pickle$test_case
  drop_null(list(
    id = test_case$id,
    pickleId = pickle$message$id,
    testSteps = c(map(test_case$before, hook_step), map(pickle$steps, pickle_step), map(test_case$after, hook_step)),
    testRunStartedId = test_run_started_id
  ))
}

#' The TestStepResult of a step or a hook. A step or a hook that failed, is
#' pending or skipped has the exception it raised: its error, or the
#' condition of `pending()` or `skip_scenario()`, like a PendingException or
#' a SkippedException.
#' @noRd
test_step_result <- function(result) {
  error <- result$error
  raised <- result$status %in% c("failed", "pending", "skipped") && !is.null(error)
  drop_null(list(
    status = toupper(result$status),
    duration = duration(result$duration),
    message = if (!is.null(error)) {
      paste(c(conditionMessage(error), if (!is.null(backtrace(error))) "Backtrace:", backtrace(error)), collapse = "\n")
    },
    exception = if (raised) exception_message(error)
  ))
}

exception_message <- function(error) {
  wrapped <- inherits(error, c("cucumber_step_error", "cucumber_step_failure", "cucumber_hook_error"))
  cause <- if (wrapped) error$parent else error
  drop_null(list(type = class(cause)[[1]], message = conditionMessage(cause), stackTrace = backtrace(error)))
}

#' An error's backtrace as plain text, or `NULL` if it has none
#' @noRd
backtrace <- function(error) {
  trace <- error$trace
  if (inherits(trace, "rlang_trace") && nrow(trace) > 0) paste(cli::ansi_strip(format(trace)), collapse = "\n")
}

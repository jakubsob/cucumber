# Full examples are read from the acceptance tests when the article is built, so they
# are the files those tests run. Each file a scenario writes is a tab, then the code it
# runs with what it prints when it's run on those files, in the Console tab. The
# tabs are Bootstrap 5 markup: pkgdown rewrites Quarto's tabsets.
acceptance_example <- function(feature, scenario, pretty = FALSE) {
  path <- file.path("..", "tests", "acceptance", feature)
  document <- cucumber:::parse_gherkin(readLines(path, encoding = "UTF-8"), uri = path)
  steps <- scenario_steps(document$feature$children, scenario)
  if (is.null(steps)) {
    stop("No scenario \"", scenario, "\" in ", path)
  }
  files <- list()
  code <- NULL
  for (step in steps) {
    file <- regmatches(step$text, regexec("^a file named \"(.*)\" with$", step$text))[[1]][2]
    if (startsWith(step$text, "I run")) {
      code <- step$docString$content
      break
    }
    if (!is.na(file)) {
      files[[file]] <- step$docString$content
    }
  }
  tabs <- Map(code_block, files, vapply(names(files), file_language, character(1)))
  # Feature files first, also those a Background writes
  tabs <- tabs[order(!grepl("\\.feature", names(tabs)))]
  if (pretty) code <- with_pretty_reporter(code)
  # The code, as R so pkgdown links its functions to their docs, then its output
  tabs[["Console"]] <- c(code_block(code, "r"), "", code_block(run_example(files, code), "console-output"))
  knitr::asis_output(ide_tabs(tabs, scenario))
}

# Examples of ways to do the same thing, each a tab of the examples' own tabs. `scenarios`
# are the scenarios' names, named by the tabs' labels
acceptance_examples <- function(feature, scenarios, pretty = FALSE) {
  tabs <- lapply(scenarios, \(scenario) acceptance_example(feature, scenario, pretty))
  knitr::asis_output(ide_tabs(tabs, paste(scenarios, collapse = " ")))
}

# Lines of each tab, named by their labels, as tabs. Their ids start with `id`, so it's
# unique to the tabs in the article
ide_tabs <- function(tabs, id) {
  ids <- paste0(gsub("[^a-z0-9]+", "-", tolower(id)), "-", seq_along(tabs))
  active <- c(" active", rep("", length(tabs) - 1))
  buttons <- sprintf(
    paste0(
      '<li class="nav-item" role="presentation">',
      '<button class="nav-link%s" data-bs-toggle="tab" data-bs-target="#%s" type="button" role="tab">%s</button></li>'
    ),
    active, ids, names(tabs)
  )
  panes <- unlist(Map(\(id, active, lines) {
    c(sprintf('::: {#%s .tab-pane%s role="tabpanel"}', id, sub(" ", " .", active)), "", lines, "", ":::")
  }, ids, active, tabs))
  paste(c(
    "::: {.ide-tabs}",
    "```{=html}", '<ul class="nav nav-tabs" role="tablist">', buttons, "</ul>", "```", "",
    "::: {.tab-content}", panes, ":::",
    ":::"
  ), collapse = "\n")
}

# The steps of a scenario, after those of the Backgrounds of its Feature and Rule
scenario_steps <- function(children, name, background = list()) {
  for (child in children) {
    if (!is.null(child$background)) {
      background <- c(background, child$background$steps)
    }
  }
  for (child in children) {
    if (!is.null(child$scenario) && child$scenario$name == name) {
      return(c(background, child$scenario$steps))
    }
    if (!is.null(child$rule)) {
      found <- scenario_steps(child$rule$children, name, background)
      if (!is.null(found)) return(found)
    }
  }
  NULL
}

# The default reporter shows only counts. With `pretty`, test() and run() calls without
# a reporter get the pretty one, for examples that need to show each scenario and its steps
with_pretty_reporter <- function(code) {
  calls <- lapply(parse(text = code), \(call) {
    if (is.call(call) && deparse(call[[1]]) %in% c("test", "run") && is.null(call$reporter)) {
      call$reporter <- quote(CucumberPrettyReporter$new())
    }
    call
  })
  paste(vapply(calls, deparse1, character(1)), collapse = "\n")
}

# What the code prints in a directory with the files, like in the console: messages
# where they're signalled, and an error as the console shows it
run_example <- function(files, code) {
  dir <- tempfile()
  for (file in names(files)) {
    dir.create(dirname(file.path(dir, file)), recursive = TRUE, showWarnings = FALSE)
    writeLines(files[[file]], file.path(dir, file))
  }
  output <- withr::with_dir(dir, utils::capture.output(withCallingHandlers(
    tryCatch(eval(parse(text = code), new.env()), error = \(e) cat("Error:", conditionMessage(e), "\n")),
    message = \(m) {
      cat(conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )))
  output <- cli::ansi_strip(output)
  # Without the empty lines the output starts with
  output[cumsum(nzchar(trimws(output))) > 0]
}

code_block <- function(content, language) {
  # A fence longer than any run of backticks in the content, so it can hold a fence
  runs <- nchar(unlist(regmatches(content, gregexpr("`+", content))))
  fence <- strrep("`", max(3, runs + 1))
  c(paste0(fence, language), content, fence)
}

file_language <- function(file) {
  if (grepl("\\.feature$", file)) {
    "gherkin"
  } else if (grepl("\\.md$", file)) {
    "markdown"
  } else if (grepl("\\.R$", file)) {
    "r"
  } else {
    ""
  }
}

before(function(context, scenario) {
  context$tempdir <- fs::path(tempdir(), paste0("test_", as.character(runif(1))))
})

given("a file named {string} with", function(filename, code, context) {
  file <- fs::path(context$tempdir, filename)
  fs::dir_create(fs::path_dir(file))
  writeLines(code, file)
})

# Like test() in a testthat file of a package whose tests/testthat.R has no
# library(cucumber). The attached cucumber is restored when the scenario ends.
given("cucumber isn't attached", function(context) {
  attached <- as.environment("package:cucumber")
  detach("package:cucumber")
  withr::defer({
    if ("package:cucumber" %in% search()) detach("package:cucumber")
    attach(attached, name = "package:cucumber", warn.conflicts = FALSE)
  }, envir = context)
})

given("a package", function(context) {
  fs::dir_create(context$tempdir)
  writeLines(c("Package: example", "Version: 0.1.0"), fs::path(context$tempdir, "DESCRIPTION"))
})

# With `catch_error`, an error of the code is kept in `context$error` instead of failing the step
run_code <- function(code, context, catch_error = FALSE) {
  # Each test() and run() of the code also writes its run as Cucumber Messages, read into
  # `context$run`, so the results of the run are checked whatever the reporter prints
  record <- function(runner) {
    function(..., reporter) {
      # A reporter that isn't cucumber's gets the error of test() or run(), not of the recorder's CucumberMultiReporter
      if (!is.null(reporter) && !inherits(reporter, "CucumberReporter")) return(runner(..., reporter = reporter))
      messages <- tempfile(fileext = ".ndjson")
      # A run stopped before it started writes no messages, and has no results
      context$run <- NULL
      on.exit(if (fs::file_exists(messages)) context$run <- read_messages(messages))
      recorder <- CucumberMessagesReporter$new(messages)
      runner(..., reporter = CucumberMultiReporter$new(purrr::compact(list(reporter, recorder))))
    }
  }
  test <- function(..., reporter = CucumberProgressReporter$new()) record(cucumber::test)(..., reporter = reporter)
  run <- function(..., reporter = eval(formals(cucumber::run)$reporter, asNamespace("cucumber"))) {
    record(cucumber::run)(..., reporter = reporter)
  }
  cucumber:::local_registry(cucumber:::new_registry())
  withr::with_dir(context$tempdir, {
    # Messages are output too, printed where they're signalled
    output <- utils::capture.output(withCallingHandlers({
      if (catch_error) {
        context$error <- tryCatch(
          {
            eval(parse(text = code))
            NULL
          },
          error = identity
        )
      } else {
        context$result <- eval(parse(text = code))
      }
    }, message = function(m) {
      cat(conditionMessage(m))
      invokeRestart("muffleMessage")
    }))
    context$output <- cli::ansi_strip(output)
  })
}

when("I run", function(code, context) run_code(code, context))

when("I run it and it fails", function(code, context) run_code(code, context, catch_error = TRUE))

# Like in the console: testthat isn't attached, and there is no teardown
# environment and no reporter, so the scenarios aren't reported to the testthat
# run of these steps
run_outside_testthat <- function(code, context, catch_error = FALSE) {
  if ("package:testthat" %in% search()) {
    detach("package:testthat")
    on.exit(if (!"package:testthat" %in% search()) attachNamespace("testthat"))
  }
  rlang::with_bindings(
    run_code(code, context, catch_error),
    teardown_env = NULL,
    reporter = NULL,
    .env = utils::getFromNamespace("the", "testthat")
  )
}

when("I run outside of a testthat run", function(code, context) run_outside_testthat(code, context))

when("I run outside of a testthat run and it fails", function(code, context) {
  run_outside_testthat(code, context, catch_error = TRUE)
})

# The steps of the last run's scenarios, and with `hooks` their hooks, in the
# order they ran. A hook is its keyword, `Before` or `After`.
run_steps <- function(context, hooks = FALSE) {
  steps <- context$run$steps
  if (!hooks) steps <- steps[!steps$keyword %in% c("Before", "After"), ]
  tibble::tibble(
    scenario = steps$scenario,
    step = trimws(paste(steps$keyword, steps$text)),
    status = steps$status
  )
}

then("the steps have these results:", function(expected, context) {
  expect_equal(as.data.frame(run_steps(context)[names(expected)]), as.data.frame(expected))
})

then("the steps and hooks have these results:", function(expected, context) {
  expect_equal(as.data.frame(run_steps(context, hooks = TRUE)[names(expected)]), as.data.frame(expected))
})

then("the scenarios have these results:", function(expected, context) {
  scenarios <- context$run$scenarios
  actual <- tibble::tibble(
    scenario = scenarios$name,
    status = scenarios$status,
    attempts = as.character(scenarios$attempts)
  )
  expect_equal(as.data.frame(actual[names(expected)]), as.data.frame(expected))
})

# The attachments of the last run: the step or hook each one is attached to,
# like `When I open the page` or `Before`, its media type, body and file name
run_attachments <- function(context) {
  q <- cucumber:::new_query()
  for (envelope in context$run$envelopes) q$update(envelope)
  attachments <- Filter(Negate(is.null), lapply(context$run$envelopes, `[[`, "attachment"))
  attached_to <- vapply(attachments, \(attachment) {
    if (!is.null(attachment$testRunHookStartedId)) {
      hook <- q$hooks[[q$test_run_hooks_started[[attachment$testRunHookStartedId]]$hookId]]
      return(if (hook$type == "BEFORE_TEST_RUN") "BeforeAll" else "AfterAll")
    }
    test_step <- q$test_steps[[attachment$testStepId]]
    if (is.null(test_step$pickleStepId)) {
      return(if (startsWith(q$hooks[[test_step$hookId]]$type, "BEFORE")) "Before" else "After")
    }
    pickle_step <- q$pickle_steps[[test_step$pickleStepId]]
    paste0(q$step_of(pickle_step)$keyword, pickle_step$text)
  }, character(1))
  tibble::tibble(
    step = attached_to,
    media_type = vapply(attachments, \(attachment) attachment$mediaType, character(1)),
    body = vapply(attachments, \(attachment) attachment$body, character(1)),
    encoding = vapply(attachments, \(attachment) attachment$contentEncoding, character(1)),
    file_name = vapply(attachments, \(attachment) attachment$fileName %||% "", character(1))
  )
}

then("the attachments are:", function(expected, context) {
  expect_equal(as.data.frame(run_attachments(context)[names(expected)]), as.data.frame(expected))
})

# How many messages of each type the last run wrote, of the types in the table
then("the messages have these types and quantities:", function(expected, context) {
  types <- vapply(context$run$envelopes, names, character(1))
  actual <- vapply(expected$type, \(type) as.character(sum(types == type)), character(1), USE.NAMES = FALSE)
  expect_equal(actual, expected$count)
})

then("no scenario ran", function(context) {
  expect_equal(nrow(context$run$scenarios), 0)
})

then("it passes", function(context) {
  results <- as.data.frame(context$result)
  expect_gt(nrow(results), 0)
  expect_equal(sum(results$error), 0)
  expect_equal(sum(results$failed), 0)
  expect_equal(sum(results$skipped), 0)
  expect_true(all(results$passed > 0))
})

then("the results are of these files:", function(expected, context) {
  results <- as.data.frame(context$result)
  actual <- tibble::tibble(scenario = sub("^Scenario: ", "", results$test), file = results$file)
  expect_equal(as.data.frame(actual), as.data.frame(expected))
})

# The warnings of the last test() run, by scenario
then("the scenarios have these warnings:", function(expected, context) {
  warnings <- do.call(rbind, lapply(context$result, \(test) {
    messages <- vapply(Filter(testthat:::expectation_warning, test$results), conditionMessage, character(1))
    data.frame(scenario = rep(sub("^Scenario: ", "", test$test), length(messages)), warning = messages)
  }))
  expect_equal(warnings, as.data.frame(expected))
})

# How many expectations passed and warnings testthat got for each scenario of the last test() run
then("testthat counts these results of the scenarios:", function(expected, context) {
  results <- as.data.frame(context$result)
  actual <- tibble::tibble(
    scenario = sub("^Scenario: ", "", results$test),
    passed = as.character(results$passed),
    warnings = as.character(results$warning)
  )
  expect_equal(as.data.frame(actual[names(expected)]), as.data.frame(expected))
})

# The testthat context of each test of the last run, empty for a test without one
then("testthat reports the tests in these contexts:", function(expected, context) {
  actual <- tibble::tibble(
    test = vapply(context$result, \(test) test$test, character(1)),
    context = vapply(context$result, \(test) test$context %||% "", character(1))
  )
  expect_equal(as.data.frame(actual), as.data.frame(expected))
})

# Where testthat's results of the last run say each scenario failed or skipped, as `file:line`
expect_result_locations <- function(classes, expected, context) {
  results <- lapply(context$result, \(test) {
    result <- Find(\(result) inherits(result, classes), test$results)
    if (is.null(result)) return(NULL)
    srcref <- result$srcref
    location <- if (inherits(srcref, "srcref")) {
      paste0(attr(srcref, "srcfile")$filename, ":", srcref[[1]])
    } else {
      NA_character_
    }
    data.frame(scenario = sub("^Scenario: ", "", test$test), location = location)
  })
  expect_equal(do.call(rbind, results), as.data.frame(expected))
}

then("the scenarios failed at these locations:", function(expected, context) {
  expect_result_locations(c("expectation_failure", "expectation_error"), expected, context)
})

then("the scenarios skipped at these locations:", function(expected, context) {
  expect_result_locations("expectation_skip", expected, context)
})

then("the scenarios warned at these locations:", function(expected, context) {
  expect_result_locations("expectation_warning", expected, context)
})

# Every result of the run is a testthat skip, with this reason
then("the results are skipped with {string}", function(reason, context) {
  results <- unlist(lapply(context$result, `[[`, "results"), recursive = FALSE)
  expect_gt(length(results), 0)
  expect_true(all(vapply(results, testthat:::expectation_skip, logical(1))))
  expect_true(all(grepl(reason, vapply(results, conditionMessage, character(1)), fixed = TRUE)))
})

then("only {string} was run", function(feature_name, context) {
  results <- as.data.frame(context$result)
  expect_setequal(results$context, sprintf("Feature: %s", feature_name))
})

then("it ran {string}", function(test_name, context) {
  results <- as.data.frame(context$result)
  expect_true(test_name %in% results$test, info = paste(results$test, collapse = ", "))
})

then("these scenarios ran in this order:", function(scenarios, context) {
  results <- as.data.frame(context$result)
  expect_equal(results$test, paste("Scenario:", scenarios$scenario))
})

then("only these scenarios ran:", function(scenarios, context) {
  results <- as.data.frame(context$result)
  expect_equal(sort(results$test), sort(paste("Scenario:", scenarios$scenario)))
})

then("the scenario {string} is {word} with {string}", function(name, outcome, message, context) {
  test <- Find(\(test) test$test == paste("Scenario:", name), context$result)
  results <- Filter(\(result) !inherits(result, "expectation_success"), test$results)
  expect_length(results, 1)
  expect_s3_class(results[[1]], c(skipped = "expectation_skip", failed = "expectation_failure")[[outcome]])
  expect_equal(conditionMessage(results[[1]]), message)
})

# The error as R shows it, with the calls it names, to read it like a snapshot.
# Where a call is in cucumber's code is left out, as its lines change with the code.
shown_error <- function(error) {
  shown <- if (inherits(error, "rlang_error")) {
    format(error, backtrace = FALSE)
  } else if (is.null(conditionCall(error))) {
    paste("Error:", conditionMessage(error))
  } else {
    paste0("Error in ", deparse1(conditionCall(error)), ": ", conditionMessage(error))
  }
  lines <- strsplit(cli::ansi_strip(shown), "\n")[[1]]
  # Without rlang's class line, `<error/rlang_error>`
  lines <- lines[!grepl("^<error/", lines)]
  sub(" at cucumber/R/[^ ]+:[0-9]+:[0-9]+:$", ":", lines)
}

then("it fails with", function(message, context) {
  expect_false(is.null(context$error))
  expect_equal(paste(shown_error(context$error), collapse = "\n"), message)
})

# Each failure, error and warning testthat got from the last run, in the order
# they happened, under a header with its kind and its scenario, like
# `[failure] Scenario: Add an item`, or only its kind outside of a scenario,
# like the error of a feature file that can't be parsed
shown_results <- function(result) {
  kinds <- c(expectation_failure = "failure", expectation_error = "error", expectation_warning = "warning")
  shown <- unlist(lapply(result, \(test) {
    lapply(test$results, \(expectation) {
      kind <- kinds[intersect(class(expectation), names(kinds))[1]]
      if (is.na(kind)) return(NULL)
      header <- paste0("[", kind, "]", if (!is.na(test$test)) paste0(" ", test$test))
      # Without spaces at the ends of lines, which editors remove from feature files
      lines <- strsplit(cli::ansi_strip(conditionMessage(expectation)), "\n")[[1]]
      paste(c(header, trimws(lines, which = "right")), collapse = "\n")
    })
  }))
  paste(shown, collapse = "\n\n")
}

then("the errors are", function(expected, context) {
  expect_equal(shown_results(context$result), expected)
})

then("the output includes", function(text, context) {
  # Compare line by line, ignoring indentation
  needle <- paste(trimws(strsplit(text, "\n")[[1]]), collapse = "\n")
  output <- paste(trimws(context$output), collapse = "\n")
  expect_true(
    grepl(needle, output, fixed = TRUE),
    info = paste0("Expected:\n", needle, "\n\nIn output:\n", output)
  )
})

# Each line is in the output after the line before it, with other lines in between
then("the output includes these lines in order:", function(text, context) {
  lines <- trimws(strsplit(text, "\n")[[1]])
  output <- trimws(context$output)
  at <- 0
  for (line in lines) {
    found <- which(output == line & seq_along(output) > at)
    expect_true(
      length(found) > 0,
      info = paste0("Missing in order: ", line, "\n\nIn output:\n", paste(output, collapse = "\n"))
    )
    at <- found[1]
  }
})

# Each line is a regular expression, for output that varies, like durations
then("the output includes lines matching these patterns in order:", function(text, context) {
  patterns <- trimws(strsplit(text, "\n")[[1]])
  output <- trimws(context$output)
  at <- 0
  for (pattern in patterns) {
    found <- which(grepl(pattern, output) & seq_along(output) > at)
    expect_true(
      length(found) > 0,
      info = paste0("Missing in order: ", pattern, "\n\nIn output:\n", paste(output, collapse = "\n"))
    )
    at <- found[1]
  }
})

then("the output includes {string}", function(text, context) {
  output <- paste(context$output, collapse = "\n")
  expect_true(grepl(text, output, fixed = TRUE), info = output)
})

then("the output includes {string} once", function(text, context) {
  output <- paste(context$output, collapse = "\n")
  expect_equal(lengths(regmatches(output, gregexpr(text, output, fixed = TRUE))), 1, info = output)
})

then("the output includes {string} {int} time(s)", function(text, n, context) {
  output <- paste(context$output, collapse = "\n")
  expect_equal(lengths(regmatches(output, gregexpr(text, output, fixed = TRUE))), n, info = output)
})

then("the output is empty", function(context) {
  expect_equal(trimws(paste(context$output, collapse = "\n")), "")
})

then("the output doesn't include {string}", function(text, context) {
  output <- paste(context$output, collapse = "\n")
  expect_false(grepl(text, output, fixed = TRUE), info = output)
})

# The test cases of a JUnit report: their class name, name, result (passed,
# failure or skipped) and the message of a failure
junit_test_cases <- function(file, context) {
  xml <- xml2::read_xml(fs::path(context$tempdir, file))
  cases <- xml2::xml_find_all(xml, "//testcase")
  outcome <- lapply(cases, \(case) xml2::xml_find_first(case, "failure|skipped"))
  tibble::tibble(
    classname = xml2::xml_attr(cases, "classname"),
    name = xml2::xml_attr(cases, "name"),
    result = vapply(
      outcome, \(node) if (inherits(node, "xml_missing")) "passed" else xml2::xml_name(node), character(1)
    ),
    message = vapply(outcome, \(node) rlang::`%|%`(xml2::xml_attr(node, "message"), ""), character(1)),
    output = xml2::xml_text(xml2::xml_find_first(cases, "system-out"))
  )
}

then("the JUnit report {string} has these test cases:", function(file, expected, context) {
  actual <- junit_test_cases(file, context)
  actual$message <- sub("\n.*", "", actual$message)
  expect_equal(as.data.frame(actual[names(expected)]), as.data.frame(expected))
})

then("the output of the test case {string} in the JUnit report {string} is", function(name, file, output, context) {
  cases <- junit_test_cases(file, context)
  expect_equal(trimws(cases$output[cases$name == name]), output)
})

# How the HTML report shows a step: its text, its status and its error, as a
# list of [step, status, error]. The official report renders its steps with
# JavaScript, so the report is read as a browser shows it. It collapses
# features whose scenarios passed, so they're opened first, as a reader would,
# and the steps are read once none is collapsed.
REPORT_STEPS_JS <- "(() => {
  const collapsed = document.querySelectorAll('button[aria-expanded=false]');
  collapsed.forEach(button => button.click());
  if (collapsed.length > 0) return [];
  return [...document.querySelectorAll('li[data-status]')].map(li => [
    li.querySelector('h3').textContent,
    li.dataset.status.toLowerCase(),
    li.querySelector('pre')?.textContent ?? ''
  ]);
})()"

# What the HTML report shows, as a browser shows it: `js` returns a list of
# what it reads, or an empty one until the report is rendered and open
read_report <- function(file, js, context) {
  session <- chromote::ChromoteSession$new()
  on.exit(session$close())
  session$go_to(paste0("file://", fs::path(context$tempdir, file)))
  js <- paste0("JSON.stringify(", js, ")")
  read <- function() {
    shown <- jsonlite::fromJSON(session$Runtime$evaluate(js, returnByValue = TRUE)$result$value, simplifyVector = FALSE)
    if (length(shown) == 0) stop("The report shows nothing yet")
    shown
  }
  # Wait for the official report to render and open
  purrr::insistently(
    read,
    purrr::rate_backoff(pause_base = 0.05, pause_min = 0, max_times = 8, jitter = FALSE)
  )()
}

# Each step the report shows, with its status and the first line of its error
then("the HTML report {string} shows these steps:", function(file, expected, context) {
  steps <- read_report(file, REPORT_STEPS_JS, context)
  shown <- tibble::tibble(
    step = trimws(gsub("\\s+", " ", vapply(steps, `[[`, character(1), 1))),
    status = vapply(steps, `[[`, character(1), 2),
    error = vapply(steps, \(step) sub("\n.*", "", step[[3]]), character(1))
  )
  expect_equal(as.data.frame(shown[names(expected)]), as.data.frame(expected))
})

# Each attachment the HTML report shows under a step: an image, with its file
# name, or text, with its first line
REPORT_ATTACHMENTS_JS <- "(() => {
  const collapsed = document.querySelectorAll('button[aria-expanded=false]');
  collapsed.forEach(button => button.click());
  if (collapsed.length > 0) return [];
  return [...document.querySelectorAll('li[data-status]')].flatMap(li =>
    [...li.querySelectorAll(':scope > div > ol > li')].map(attachment => {
      const image = attachment.querySelector('img');
      return [
        li.querySelector('h3').textContent,
        image ? 'image' : 'text',
        image ? attachment.querySelector('summary').textContent : attachment.querySelector('pre').textContent
      ];
    })
  );
})()"

then("the HTML report {string} shows these attachments:", function(file, expected, context) {
  attachments <- read_report(file, REPORT_ATTACHMENTS_JS, context)
  shown <- tibble::tibble(
    step = trimws(gsub("\\s+", " ", vapply(attachments, `[[`, character(1), 1))),
    kind = vapply(attachments, `[[`, character(1), 2),
    content = vapply(attachments, \(attachment) sub("\n.*", "", attachment[[3]]), character(1))
  )
  expect_equal(as.data.frame(shown[names(expected)]), as.data.frame(expected))
})

then("there is a file {string}", function(file, context) {
  expect_true(fs::file_exists(fs::path(context$tempdir, file)))
})

then("there is no file {string}", function(file, context) {
  expect_false(fs::file_exists(fs::path(context$tempdir, file)))
})

after(function(context, scenario) {
  # Cleanup environment if package was loaded, attached or only its namespace,
  # like by test() in R CMD check
  withr::with_dir(context$tempdir, {
    if (fs::file_exists("DESCRIPTION")) {
      package_name <- desc::desc_get_field("Package")
      if (paste0("package:", package_name) %in% search() || isNamespaceLoaded(package_name)) {
        pkgload::unload(package_name, quiet = TRUE)
      }
    }
  })
  fs::dir_delete(context$tempdir)
})

# The help page of a topic of the package, as text, like `?topic` shows it
help_page <- function(topic, context) {
  rd <- fs::path(context$tempdir, "man", paste0(topic, ".Rd"))
  text <- withr::with_options(
    list(useFancyQuotes = FALSE),
    utils::capture.output(tools::Rd2txt(rd, options = list(underline_titles = FALSE)))
  )
  paste(text, collapse = "\n")
}

then("the help page {string} includes", function(topic, text, context) {
  # Compare line by line, ignoring indentation
  needle <- paste(trimws(strsplit(text, "\n")[[1]]), collapse = "\n")
  page <- paste(trimws(strsplit(help_page(topic, context), "\n")[[1]]), collapse = "\n")
  expect_true(grepl(needle, page, fixed = TRUE), info = paste0("Expected:\n", needle, "\n\nIn help page:\n", page))
})

then("the help page {string} includes {string}", function(topic, text, context) {
  page <- help_page(topic, context)
  expect_true(grepl(text, page, fixed = TRUE), info = page)
})

then("the help page {string} doesn't include {string}", function(topic, text, context) {
  page <- help_page(topic, context)
  expect_false(grepl(text, page, fixed = TRUE), info = page)
})

# A block of Gherkin code of a pkgdown reference page, as text
then("the reference page {string} has the Gherkin block", function(topic, text, context) {
  html <- xml2::read_html(fs::path(context$tempdir, "docs", "reference", paste0(topic, ".html")))
  blocks <- trimws(xml2::xml_text(xml2::xml_find_all(html, "//pre[contains(@class, 'gherkin')]/code")))
  expect_true(
    text %in% blocks,
    info = paste0("Expected:\n", text, "\n\nGherkin blocks:\n", paste(blocks, collapse = "\n\n"))
  )
})

# The tokens of the Gherkin blocks of a pkgdown reference page, with their classes
then("the reference page {string} highlights the Gherkin", function(topic, table, context) {
  html <- xml2::read_html(fs::path(context$tempdir, "docs", "reference", paste0(topic, ".html")))
  spans <- xml2::xml_find_all(html, "//pre[contains(@class, 'gherkin')]/code//span[@class]")
  tokens <- paste(trimws(xml2::xml_text(spans)), "-", xml2::xml_attr(spans, "class"))
  expected <- paste(table$token, "-", table$class)
  expect_true(all(expected %in% tokens), info = paste0(
    "Missing:\n", paste(setdiff(expected, tokens), collapse = "\n"),
    "\n\nTokens:\n", paste(tokens, collapse = "\n")
  ))
})

then("the file {string} has these lines:", function(file, lines, context) {
  expect_equal(readLines(fs::path(context$tempdir, file)), strsplit(lines, "\n")[[1]])
})

then("the file {string} includes {string} {int} time(s)", function(file, text, n, context) {
  content <- paste(readLines(fs::path(context$tempdir, file)), collapse = "\n")
  expect_equal(lengths(regmatches(content, gregexpr(text, content, fixed = TRUE))), n, info = content)
})

then("the file {string} is empty", function(file, context) {
  expect_equal(readLines(fs::path(context$tempdir, file)), character())
})

given("a package that uses the 3rd edition of testthat", function(context) {
  fs::dir_create(context$tempdir)
  writeLines(
    c("Package: example", "Version: 0.1.0", "Config/testthat/edition: 3"),
    fs::path(context$tempdir, "DESCRIPTION")
  )
})

# Snapshots: feature files in tests/testthat, each with one scenario that
# snapshots a value, run by test() or by run() in a testthat file
snapshots_dir <- "tests/testthat"

write_snapshot_feature <- function(file, context) {
  feature <- context$snapshot_features[[file]]
  steps <- c(
    if (!is.null(feature$before)) paste("Given", feature$before),
    sprintf('Then the snapshot of "%s" matches', feature$value)
  )
  lines <- if (grepl("[.]md$", file)) {
    c(paste("# Feature:", file), "", paste("## Scenario:", feature$scenario), "", paste("*", steps))
  } else {
    c(paste("Feature:", file), paste("  Scenario:", feature$scenario), paste("   ", steps))
  }
  path <- fs::path(context$tempdir, snapshots_dir, file)
  fs::dir_create(fs::path_dir(path))
  writeLines(lines, path)
}

write_snapshot_steps <- function(context) {
  fs::dir_create(fs::path(context$tempdir, snapshots_dir))
  # The features show the lines of these steps, so each step keeps its line
  # nolint start: line_length_linter.
  writeLines(
    c(
      'given("it fails", function(context) stop("Failed on purpose"))',
      'given("it doesn\'t meet an expectation", function(context) expect_true(FALSE))',
      'given("it fails the first time", function(context) {',
      '  if (!file.exists("failed-once")) {',
      '    file.create("failed-once")',
      '    stop("Failed the first time")',
      "  }",
      "})",
      'then("the snapshot of {string} matches", function(value, context) expect_snapshot(value))',
      'then("the snapshot of {string} for {string} matches", function(value, variant, context) expect_snapshot(value, variant = variant))',
      'then("the snapshot of the error {string} matches", function(message, context) expect_snapshot(stop(message), error = TRUE))',
      'then("the snapshot of the temporary directory matches", function(context) {',
      '  expect_snapshot(cat(tempdir()), transform = function(lines) sub(tempdir(), "<tempdir>", lines, fixed = TRUE))',
      "})",
      'then("the snapshot of the value {string} matches", function(value, context) expect_snapshot_value(value, style = "deparse"))',
      'given("the file snapshot {string} is announced", function(name, context) announce_snapshot_file(name = name))',
      'then("the file snapshot {string} of {string} matches", function(name, value, context) {',
      '  file <- tempfile(fileext = ".txt")',
      "  writeLines(value, file)",
      "  expect_snapshot_file(file, name)",
      "})"
    ),
    fs::path(context$tempdir, snapshots_dir, "setup-snapshot-steps.R")
  )
  # nolint end
}

given("the steps that take snapshots", function(context) write_snapshot_steps(context))

given(
  "a feature file {string} with a scenario {string} that snapshots {string}",
  function(file, scenario, value, context) {
    context$snapshot_features[[file]] <- list(scenario = scenario, value = value)
    write_snapshot_steps(context)
    write_snapshot_feature(file, context)
  }
)

given("the scenario {string} of {string} snapshots {string}", function(scenario, file, value, context) {
  context$snapshot_features[[file]]$value <- value
  write_snapshot_feature(file, context)
})

given("the scenario {string} of {string} is renamed {string}", function(scenario, file, name, context) {
  context$snapshot_features[[file]]$scenario <- name
  write_snapshot_feature(file, context)
})

given("the scenario {string} of {string} starts with {string}", function(scenario, file, step, context) {
  context$snapshot_features[[file]]$before <- step
  write_snapshot_feature(file, context)
})

# Snapshots are taken outside of CRAN and R CMD check, and saved unless on CI, so
# none is set, and test() runs like in the console, outside of the testthat run of these steps
run_feature_files <- function(runner, args, context, ci = FALSE, cran = FALSE) {
  stopifnot(runner %in% c("test()", "run()"))
  context$run <- NULL
  code <- if (runner == "test()") {
    sprintf('test("%s", stop_on_failure = FALSE%s)', snapshots_dir, args)
  } else {
    messages <- tempfile(fileext = ".ndjson")
    writeLines(
      sprintf('cucumber::run(reporter = cucumber::CucumberMessagesReporter$new("%s")%s)', messages, args),
      fs::path(context$tempdir, snapshots_dir, "test-acceptance.R")
    )
    # A run stopped before it started writes no messages
    on.exit(if (fs::file_exists(messages)) context$run <- read_messages(messages))
    'testthat::test_local(reporter = "silent", stop_on_failure = FALSE)'
  }
  run_code(sprintf(
    "withr::with_envvar(c(NOT_CRAN = %s, CI = %s, TESTTHAT = NA, `_R_CHECK_PACKAGE_NAME_` = NA), %s)",
    if (cran) '"false"' else "NA", if (ci) '"true"' else "NA", code
  ), context)
}

when("I run the feature files with {string}", function(runner, context) {
  run_feature_files(runner, "", context)
})

when("I run the feature files with {string} on CI", function(runner, context) {
  run_feature_files(runner, "", context, ci = TRUE)
})

# Like on CRAN, where `NOT_CRAN` isn't "true"
when("I run the feature files with {string} on CRAN", function(runner, context) {
  run_feature_files(runner, "", context, cran = TRUE)
})

when("I run the feature files with {string} and {word} = TRUE", function(runner, argument, context) {
  run_feature_files(runner, sprintf(", %s = TRUE", argument), context)
})

given("the file {string} is deleted", function(file, context) {
  fs::file_delete(fs::path(context$tempdir, file))
})

when("I run the feature files with {string} and the {word} {string}", function(runner, argument, value, context) {
  run_feature_files(runner, sprintf(', %s = "%s"', argument, value), context)
})

when("I run the feature files with {string} and {word} = {int}", function(runner, argument, value, context) {
  run_feature_files(runner, sprintf(", %s = %d", argument, value), context)
})

then("the snapshot file {string} has {string} for {string}", function(file, value, scenario, context) {
  dir <- fs::path(context$tempdir, snapshots_dir)
  path <- fs::path(dir, file)
  snapshot_files <- fs::dir_ls(dir, recurse = TRUE, glob = "*.md")
  expect_true(fs::file_exists(path), info = paste("Snapshot files:", paste(snapshot_files, collapse = ", ")))
  lines <- readLines(path)
  start <- match(paste("# Scenario:", scenario), lines)
  expect_false(is.na(start), info = paste(lines, collapse = "\n"))
  end <- c(which(startsWith(lines, "# ") & seq_along(lines) > start), length(lines) + 1)[1]
  expect_true(sprintf('[1] "%s"', value) %in% trimws(lines[start:(end - 1)]), info = paste(lines, collapse = "\n"))
})

then("the snapshot file {string} for {string} has these lines:", function(file, scenario, expected, context) {
  lines <- readLines(fs::path(context$tempdir, snapshots_dir, file))
  start <- match(paste("# Scenario:", scenario), lines)
  expect_false(is.na(start), info = paste(lines, collapse = "\n"))
  end <- c(which(startsWith(lines, "# ") & seq_along(lines) > start), length(lines) + 1)[1]
  section <- trimws(lines[start:(end - 1)])
  for (line in strsplit(expected, "\n")[[1]]) expect_true(line %in% section, info = paste(lines, collapse = "\n"))
})

then("the snapshot file {string} has {int} snapshot(s) for {string}", function(file, n, scenario, context) {
  lines <- readLines(fs::path(context$tempdir, snapshots_dir, file))
  start <- match(paste("# Scenario:", scenario), lines)
  expect_false(is.na(start), info = paste(lines, collapse = "\n"))
  end <- c(which(startsWith(lines, "# ") & seq_along(lines) > start), length(lines) + 1)[1]
  expect_equal(sum(trimws(lines[start:(end - 1)]) == "Code"), n, info = paste(lines, collapse = "\n"))
})

then("the snapshot file {string} has the scenarios in this order:", function(file, expected, context) {
  lines <- readLines(fs::path(context$tempdir, snapshots_dir, file))
  expect_equal(sub("^# Scenario: ", "", grep("^# Scenario: ", lines, value = TRUE)), expected$scenario)
})

then("the snapshot file {string} has no snapshot for {string}", function(file, scenario, context) {
  lines <- readLines(fs::path(context$tempdir, snapshots_dir, file))
  expect_false(paste("# Scenario:", scenario) %in% lines, info = paste(lines, collapse = "\n"))
})

then("there is no snapshot file {string}", function(file, context) {
  expect_false(fs::file_exists(fs::path(context$tempdir, snapshots_dir, file)))
})

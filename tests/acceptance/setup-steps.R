before(function(context, scenario_name) {
  context$tempdir <- fs::path(tempdir(), paste0("test_", as.character(runif(1))))
})

given("a file named {string} with", function(filename, code, context) {
  file <- fs::path(context$tempdir, filename)
  fs::dir_create(fs::path_dir(file))
  writeLines(code, file)
})

given("a package", function(context) {
  fs::dir_create(context$tempdir)
  writeLines(c("Package: example", "Version: 0.1.0"), fs::path(context$tempdir, "DESCRIPTION"))
})

# With `catch_error`, an error of the code is kept in `context$error` instead of failing the step
run_code <- function(code, context, catch_error = FALSE) {
  # Each test() of the code also writes its run as Cucumber Messages, read into
  # `context$run`, so the results of the run are checked whatever the reporter prints
  test <- function(..., reporter = cucumber:::get_reporter()) {
    messages <- tempfile(fileext = ".ndjson")
    on.exit(if (fs::file_exists(messages)) context$run <- read_messages(messages))
    recorder <- CucumberMessagesReporter$new(messages)
    cucumber::test(..., reporter = CucumberMultiReporter$new(purrr::compact(list(reporter, recorder))))
  }
  x <- as.character(runif(1))
  .cucumber_hooks_option <- paste0(".cucumber_hooks_", x)
  .cucumber_steps_option <- paste0(".cucumber_steps_", x)
  .cucumber_parameters_option <- paste0(".cucumber_parameters_", x)
  withr::with_options(
    list(
      .cucumber_steps_option = .cucumber_steps_option,
      .cucumber_hooks_option = .cucumber_hooks_option,
      .cucumber_parameters_option = .cucumber_parameters_option,
      # Unset the outer run's reporter: nested runs demonstrate failures on purpose,
      # so their step results must not accumulate into the outer run's summary.
      # Unset, each nested test() gets a reporter of its own, as in a fresh session.
      .cucumber_reporter = NULL
    ),
    {
      cucumber:::set_default_parameters()
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
  )
  options(rlang::list2(!!.cucumber_hooks_option := NULL))
  options(rlang::list2(!!.cucumber_steps_option := NULL))
  options(rlang::list2(!!.cucumber_parameters_option := NULL))
}

when("I run", function(code, context) run_code(code, context))

when("I run it and it fails", function(code, context) run_code(code, context, catch_error = TRUE))

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
  actual <- tibble::tibble(scenario = scenarios$name, status = scenarios$status, attempts = as.character(scenarios$attempts))
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

then("no scenario ran", function(context) {
  expect_equal(nrow(context$run$scenarios), 0)
})

then("it passes", function(context) {
  results <- as.data.frame(context$result)
  expect_equal(sum(results$error), 0)
  expect_equal(sum(results$failed), 0)
  expect_equal(sum(results$skipped), 0)
  expect_true(all(results$passed > 0))
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

then("it fails with {string}", function(error_message, context) {
  expect_false(is.null(context$error))
  # Get the full error message including cli formatting
  full_message <- paste(conditionMessage(context$error), collapse = "\n")
  expect_true(
    grepl(error_message, full_message, fixed = TRUE),
    info = sprintf("Expected error to contain '%s', but got: %s", error_message, full_message)
  )
})

extract_error_messages <- function(result) {
  messages <- lapply(result, function(r) {
    lapply(r$results, function(exp) {
      if (!inherits(exp, "expectation_success") && !inherits(exp, "expectation_skip")) {
        exp$message
      }
    })
  })
  unlist(Filter(Negate(is.null), unlist(messages, recursive = FALSE)))
}

then("the error message includes {string}", function(text, context) {
  messages <- extract_error_messages(context$result)
  expect_true(
    any(vapply(messages, function(m) grepl(text, m, fixed = TRUE), logical(1))),
    info = paste("Messages found:\n", paste(messages, collapse = "\n---\n"))
  )
})

then("the error message doesn't include {string}", function(text, context) {
  messages <- extract_error_messages(context$result)
  expect_false(
    any(vapply(messages, function(m) grepl(text, m, fixed = TRUE), logical(1))),
    info = paste("Messages found:\n", paste(messages, collapse = "\n---\n"))
  )
})

then("the error message includes", function(text, context) {
  messages <- extract_error_messages(context$result)
  # Normalize whitespace so indentation differences between the feature file
  # and the error message don't matter
  needle <- paste(trimws(strsplit(text, "\n")[[1]]), collapse = " ")
  normalize <- function(s) paste(trimws(strsplit(s, "\n")[[1]]), collapse = " ")
  found <- any(vapply(messages, function(m) grepl(needle, normalize(m), fixed = TRUE), logical(1)))
  expect_true(
    found,
    info = paste0("Expected:\n", paste(text, collapse = "\n"), "\n\nIn messages:\n", paste(messages, collapse = "\n---\n"))
  )
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
    expect_true(length(found) > 0, info = paste0("Missing in order: ", line, "\n\nIn output:\n", paste(output, collapse = "\n")))
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
    expect_true(length(found) > 0, info = paste0("Missing in order: ", pattern, "\n\nIn output:\n", paste(output, collapse = "\n")))
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
    result = vapply(outcome, \(node) if (inherits(node, "xml_missing")) "passed" else xml2::xml_name(node), character(1)),
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

then("there is no file {string}", function(file, context) {
  expect_false(fs::file_exists(fs::path(context$tempdir, file)))
})

after(function(context, scenario_name) {
  # Cleanup environment if package was loaded
  withr::with_dir(context$tempdir, {
    if (fs::file_exists("DESCRIPTION")) {
      package_name <- desc::desc_get_field("Package")
      if (paste0("package:", package_name) %in% search()) {
        pkgload::unload(package_name, quiet = TRUE)
      }
    }
  })
  fs::dir_delete(context$tempdir)
})

# The help page of a topic of the package, as text, like `?topic` shows it
help_page <- function(topic, context) {
  rd <- fs::path(context$tempdir, "man", paste0(topic, ".Rd"))
  text <- withr::with_options(list(useFancyQuotes = FALSE), utils::capture.output(tools::Rd2txt(rd, options = list(underline_titles = FALSE))))
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
  expect_true(text %in% blocks, info = paste0("Expected:\n", text, "\n\nGherkin blocks:\n", paste(blocks, collapse = "\n\n")))
})

# The tokens of the Gherkin blocks of a pkgdown reference page, with their classes
then("the reference page {string} highlights the Gherkin", function(topic, table, context) {
  html <- xml2::read_html(fs::path(context$tempdir, "docs", "reference", paste0(topic, ".html")))
  spans <- xml2::xml_find_all(html, "//pre[contains(@class, 'gherkin')]/code//span[@class]")
  tokens <- paste(trimws(xml2::xml_text(spans)), "-", xml2::xml_attr(spans, "class"))
  expected <- paste(table$token, "-", table$class)
  expect_true(all(expected %in% tokens), info = paste0("Missing:\n", paste(setdiff(expected, tokens), collapse = "\n"), "\n\nTokens:\n", paste(tokens, collapse = "\n")))
})

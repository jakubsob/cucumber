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
  x <- as.character(runif(1))
  .cucumber_hooks_option <- paste0(".cucumber_hooks_", x)
  .cucumber_steps_option <- paste0(".cucumber_steps_", x)
  .cucumber_parameters_option <- paste0(".cucumber_parameters_", x)
  withr::with_options(
    list(
      .cucumber_steps_option = .cucumber_steps_option,
      .cucumber_hooks_option = .cucumber_hooks_option,
      .cucumber_parameters_option = .cucumber_parameters_option,
      # Isolate the reporter: nested runs demonstrate failures on purpose, so
      # their step results must not accumulate into the outer run's summary.
      .cucumber_reporter = cucumber::CucumberProgressReporter$new()
    ),
    {
      cucumber:::set_default_parameters()
      withr::with_dir(context$tempdir, {
        output <- utils::capture.output({
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
        })
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

then("it passes", function(context) {
  results <- as.data.frame(context$result)
  expect_equal(sum(results$error), 0)
  expect_equal(sum(results$failed), 0)
  expect_equal(sum(results$skipped), 0)
  expect_true(all(results$passed > 0))
})

# Each row of testthat's results is one scenario (or one test_that() block),
# so the counts below are of scenarios, not of expectations.
scenario_status <- function(context) {
  results <- as.data.frame(context$result)
  ifelse(
    results$error | results$failed > 0, "failed",
    ifelse(results$skipped, "skipped", "passed")
  )
}

then("it has {int} passed", function(n, context) {
  expect_equal(sum(scenario_status(context) == "passed"), n)
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

then("it has {int} errors", function(n, context) {
  results <- as.data.frame(context$result)
  expect_equal(sum(results$error), n)
})

then("it has {int} failed", function(n, context) {
  expect_equal(sum(scenario_status(context) == "failed"), n)
})

then("it has {int} skipped", function(n, context) {
  expect_equal(sum(scenario_status(context) == "skipped"), n)
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

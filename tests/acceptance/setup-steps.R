before(function(context, scenario_name) {
  context$tempdir <- fs::path(tempdir(), paste0("test_", as.character(runif(1))))
})

given("a file named {string} with", function(filename, code, context) {
  file <- fs::path(context$tempdir, filename)
  fs::dir_create(fs::path_dir(file))
  writeLines(code, file)
})

when("I run", function(code, context) {
  x <- as.character(runif(1))
  .cucumber_hooks_option <- paste0(".cucumber_hooks_", x)
  .cucumber_steps_option <- paste0(".cucumber_steps_", x)
  .cucumber_parameters_option <- paste0(".cucumber_parameters_", x)
  withr::with_options(
    list(
      .cucumber_steps_option = .cucumber_steps_option,
      .cucumber_hooks_option = .cucumber_hooks_option,
      .cucumber_parameters_option = .cucumber_parameters_option
    ),
    {
      cucumber:::set_default_parameters()
      withr::with_dir(context$tempdir, {
        withr::with_output_sink(nullfile(), {
          context$result <- eval(parse(text = code))
        })
      })
    }
  )
  options(rlang::list2(!!.cucumber_hooks_option := NULL))
  options(rlang::list2(!!.cucumber_steps_option := NULL))
  options(rlang::list2(!!.cucumber_parameters_option := NULL))
})

then("it passes", function(context) {
  results <- as.data.frame(context$result)
  expect_equal(sum(results$errors), 0)
  expect_true(sum(results$passed > 0) == nrow(results))
})

then("it has {int} passed", function(n, context) {
  results <- as.data.frame(context$result)
  expect_equal(sum(results$passed), n)
})

then("only {string} was run", function(feature_name, context) {
  results <- as.data.frame(context$result)
  expect_setequal(results$context, sprintf("Feature: %s", feature_name))
})

then("it has {int} errors", function(n, context) {
  results <- as.data.frame(context$result)
  expect_equal(sum(results$error), n)
})

then("it has {int} skipped", function(n, context) {
  results <- as.data.frame(context$result)
  expect_equal(sum(results$skipped), n)
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

then("the error message includes", function(text, context) {
  messages <- extract_error_messages(context$result)
  # text is a character vector of lines from a docstring; normalize whitespace
  # so indentation differences between the feature file and the error message don't matter
  needle <- paste(trimws(text), collapse = " ")
  normalize <- function(s) paste(trimws(strsplit(s, "\n")[[1]]), collapse = " ")
  found <- any(vapply(messages, function(m) grepl(needle, normalize(m), fixed = TRUE), logical(1)))
  expect_true(
    found,
    info = paste0("Expected:\n", paste(text, collapse = "\n"), "\n\nIn messages:\n", paste(messages, collapse = "\n---\n"))
  )
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

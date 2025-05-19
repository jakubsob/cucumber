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

given("a file named {string} with", function(filename, code, context) {
  context$tempdir <- fs::path(tempdir(), "__cucumber__")
  file <- fs::path(context$tempdir, filename)
  fs::dir_create(fs::path_dir(file))
  writeLines(code, file)
})

when("I run cucumber", function(context) {
  withr::with_options(list(
    .cucumber_steps_option = ".cucumber_steps_",
    .cucumber_hooks_option = ".cucumber_hooks_",
    .cucumber_parameters_option = ".cucumber_parameters_"
  ), {
    cucumber:::set_default_parameters()
    withr::with_dir(context$tempdir, {
      withr::with_output_sink(nullfile(), {
        context$result <- test(stop_on_failure = FALSE)
      })
    })
  })
})

then("it passes", function(context) {
  results <- as.data.frame(context$result)
  expect_equal(sum(results$errors), 0)
  expect_true(sum(results$passed > 0) == nrow(results))
})

then("it fails", function(context) {
  results <- as.data.frame(context$result)
  expect_true(sum(results$failed) > 0)
})

after(function(context, scenario_name) {
  fs::dir_delete(context$tempdir)
})

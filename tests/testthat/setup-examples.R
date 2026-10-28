.expect_snapshot <- purrr::partial(
  testthat::expect_snapshot,
  transform = function(lines) {
    lines |>
      # Remove lines that indicate progress
      stringr::str_subset("^[\\|/\\-\\\\] \\|", negate = TRUE) |>
      # Remove test timing information
      stringr::str_remove_all("\\s\\[\\d+.\\d+s\\]") |>
      # Remove test run duration
      stringr::str_remove_all("Duration:\\s\\d+.\\d+\\ss") |>
      # Mask the durations of the summary
      stringr::str_replace_all("\\d+m\\d{2}\\.\\d{3}s", "<duration>")
  }
)

.with_example_dir <- function(path, code) {
  withr::with_dir(
    system.file(fs::path("examples", path), package = "cucumber"),
    code
  )
}

test_example <- function(path, tests_path = "tests/acceptance", ...) {
  # Clear any steps registered by previous tests
  cucumber:::clear_steps()

  .with_example_dir(path, {
    .expect_snapshot(
      test(
        tests_path,
        reporter = CucumberPrettyReporter$new(),
        stop_on_failure = FALSE,
        ...
      )
    )
  })
}

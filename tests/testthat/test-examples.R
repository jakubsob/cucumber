test_example <- function(path) {
  withr::with_dir(system.file(path, package = "cucumber"), {
    testthat::expect_snapshot(
      testthat::test_dir(
        "tests/testthat",
        reporter = testthat::ProgressReporter$new(show_praise = FALSE),
        stop_on_failure = FALSE
      ),
      transform = function(lines) {
        lines |>
          # Remove lines that indicate progress
          stringr::str_subset("^[\\|/\\-\\\\] \\|", negate = TRUE) |>
          # Remove empty lines
          stringr::str_subset("^$", negate = TRUE) |>
          # Remove test timing information
          stringr::str_remove_all("\\s\\[\\d+.\\d+s\\]") |>
          # Remove test run duration
          stringr::str_remove_all("Duration:\\s\\d+.\\d+\\ss") |>
          stringr::str_trim()
      }
    )
  })
}

describe("test", {
  it("should run one feature", {
    test_example("examples/one_feature")
  })

  it("should run multiple features", {
    test_example("examples/multiple_features")
  })

  it("should run with box", {
    test_example("examples/box_support")
  })

  it("should run with shinytest2", {
    test_example("examples/shinytest2")
  })

  it("should run a Scenario with Given, When, Then, And, But keywords", {
    test_example("examples/long_scenario")
  })

  it("should run a Scenario with a Table", {
    test_example("examples/table")
  })

  it("should run a Scenario with a docstring", {
    test_example("examples/docstring")
  })

  it("should run a Scenario with custom parameters", {
    test_example("examples/custom_parameters")
  })

  it("should report success with `testthat::test_dir`", {
    test_example("examples/with_testthat_success")
  })

  it("should report failure with `testthat::test_dir`", {
    testthat::skip_if(testthat::is_checking())
    test_example("examples/with_testthat_failure")
  })
})

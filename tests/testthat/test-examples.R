test_example <- function(path, tests_path = "tests/testthat") {
  withr::with_dir(system.file(path, package = "cucumber"), {
    testthat::expect_snapshot(
      testthat::test_dir(
        tests_path,
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
    skip_on_ci()
    # nolint start
    # Produces on r-devel:
    # Superclass process has cloneable=FALSE, but subclass r_process has cloneable=TRUE. A subclass cannot be cloneable when its superclass is not cloneable, so cloning will be disabled for r_process.
    # nolint end
    skip_if(R.version$status == "Under development (unstable)")
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

  it("should run a Scenario with comments", {
    test_example("examples/comments")
  })

  it("should run before and after hooks", {
    testthat::skip_if(covr::in_covr())
    test_example("examples/hooks")
  })

  it("should run after hook, even after error in step", {
    testthat::skip_if(covr::in_covr())
    testthat::skip_if(R.version$status == "Under development (unstable)")
    test_example("examples/hooks_after_error")
  })

  it("should run a Scenario with custom parameters", {
    test_example("examples/custom_parameters")
  })

  it("should run a Scenario with snapshot test", {
    testthat::skip_on_cran()
    test_example("examples/snapshot_test")
  })

  it("should work with covr", {
    testthat::skip_if(covr::in_covr())
    withr::with_dir(
      system.file("examples/covr_support/tests/testthat", package = "cucumber"),
      {
        testthat::expect_snapshot({
          source_files <- list.files(
            c("../../R", "./steps"),
            full.names = TRUE,
            pattern = ".R$"
          )
          test_files <- list.files(".", full.names = TRUE, pattern = ".R$")
          covr::file_coverage(source_files, test_files)
        })
      }
    )
  })

  it("should work with custom steps loader", {
    test_example("examples/custom_steps_loader")
  })

  it("should work with an arbitrary test directory", {
    test_example("examples/custom_test_dir", "tests/acceptance")
  })

  it("should report success with `testthat::test_dir`", {
    test_example("examples/with_testthat_success")
  })

  it("should report failure with `testthat::test_dir`", {
    testthat::skip_if(testthat::is_checking())
    test_example("examples/with_testthat_failure")
  })

  it("should work with loading steps from setup files", {
    test_example("examples/testthat_setup_files")
  })

  it("should work with Scenario Outline", {
    test_example("examples/scenario_outline")
  })
})

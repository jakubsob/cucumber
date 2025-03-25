test_example <- function(path, tests_path = "tests/acceptance", ...) {
  withr::with_dir(system.file(path, package = "cucumber"), {
    testthat::expect_snapshot(
      cucumber::test(
        tests_path,
        reporter = testthat::ProgressReporter$new(show_praise = FALSE),
        stop_on_failure = FALSE,
        ...
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

  it("should work with an arbitrary test directory", {
    test_example("examples/custom_test_dir", "tests/e2e")
  })

  it("should report success with `testthat::test_dir`", {
    test_example("examples/with_testthat_success")
  })

  it("should report failure with `testthat::test_dir`", {
    test_example("examples/with_testthat_failure")
  })

  it("should work with loading steps from setup files", {
    test_example("examples/testthat_setup_files")
  })

  it("should work with Scenario Outline", {
    test_example("examples/scenario_outline")
  })

  it("shouldn't run testthat test files", {
    test_example("examples/with_test_files")
  })

  it("should work with testthat filtering", {
    test_example(
      "examples/with_testthat_filtering",
      filter = "guess_the_word$"
    )
  })

  it("should throw an error if no test files are found", {
    expect_error(
      test_example(
        "examples/with_testthat_filtering",
        filter = "this_feature_doesnt_exist"
      ),
      "No feature files found"
    )
  })
})

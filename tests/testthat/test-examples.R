describe("test", {
  skip_on_cran()
  it("should run one feature", {
    test_example("one_feature")
  })

  it("should run multiple features", {
    test_example("multiple_features")
  })

  it("should run with box", {
    test_example("box_support")
  })

  it("should run with shinytest2", {
    skip_on_ci()
    # nolint start
    # Produces on r-devel:
    # Superclass process has cloneable=FALSE, but subclass r_process has cloneable=TRUE. A subclass cannot be cloneable when its superclass is not cloneable, so cloning will be disabled for r_process.
    # nolint end
    skip_if(R.version$status == "Under development (unstable)")
    test_example("shinytest2")
  })

  it("should run a Scenario with Given, When, Then, And, But keywords", {
    test_example("long_scenario")
  })

  it("should run a Scenario with a Table", {
    test_example("table")
  })

  it("should run a Scenario with a docstring", {
    test_example("docstring")
  })

  it("should run a Scenario with comments", {
    test_example("comments")
  })

  it("should run before and after hooks", {
    testthat::skip_if(covr::in_covr())
    test_example("hooks")
  })

  it("should run a Scenario with custom parameters", {
    test_example("custom_parameters")
  })

  it("should run a Scenario with snapshot test", {
    testthat::skip_on_cran()
    test_example("snapshot_test")
  })

  it("should work with an arbitrary test directory", {
    test_example("custom_test_dir", "tests/e2e")
  })

  it("should report success with `testthat::test_dir`", {
    test_example("with_testthat_success")
  })

  it("should work with loading steps from setup files", {
    test_example("testthat_setup_files")
  })

  it("should work with Scenario Outline", {
    test_example("scenario_outline")
  })

  it("shouldn't run testthat test files", {
    test_example("with_test_files")
  })

  it("should work with testthat filtering", {
    test_example(
      "with_testthat_filtering",
      filter = "guess_the_word$"
    )
  })

  it("should run all scenarios when no tags filter is given", {
    result <- .with_example_dir("tags", {
      cucumber::test(
        "tests/acceptance",
        stop_on_failure = FALSE,
        reporter = testthat::SilentReporter$new()
      )
    })
    df <- as.data.frame(result)
    expect_equal(nrow(df), 2)
  })

  it("should run tests with custom loading of steps and support code", {
    .with_example_dir("custom_loading", {
      .test <- function() {
        env <- new.env()
        source("tests/acceptance/steps/steps.R", local = env)
        source("tests/acceptance/support/expect.R", local = env)
        cucumber::test(
          tests_path = "tests/acceptance",
          reporter = CucumberProgressReporter$new(show_praise = FALSE),
          stop_on_failure = FALSE,
          env = env
        )
      }
      .expect_snapshot(.test())
    })
  })
})

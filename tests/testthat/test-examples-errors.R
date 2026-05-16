describe("test / error handling", {
  skip_on_cran()

  it("should throw an error if no steps are defined", {
    test_example("no_steps")
  })

  it("should throw an error if no test files are found", {
    test_example(
      "with_testthat_filtering",
      filter = "this_feature_doesnt_exist"
    )
  })

  it("should show clean trace when a step throws an error", {
    test_example("step_error")
  })

  it("should run after hook, even after error in step", {
    testthat::skip_if(covr::in_covr())
    testthat::skip_if(R.version$status == "Under development (unstable)")
    test_example("hooks_after_error")
  })

  it("should report failure with `testthat::test_dir`", {
    test_example("with_testthat_failure")
  })

  it("should show a snippet when a step has no definition", {
    test_example("missing_step")
  })

  it("should show an error when a step has duplicate definitions", {
    test_example("duplicate_step")
  })

  it("should show an error when a feature file is invalid", {
    test_example("invalid_feature")
  })
})

describe("test", {
  it("should report success with `testthat::test_dir`", {
    testthat::skip_if(testthat::is_checking())
    withr::with_options(
      list(
        steps = .steps(),
        parameters = get_parameters()
      ), {
        withr::with_dir(system.file("examples/with_testthat_success", package = "cucumber"), {
          testthat::expect_snapshot(
            capture.output(
              testthat::test_dir(
                "tests/testthat",
                reporter = ProgressReporter$new(show_praise = FALSE)
              )
            )
          )
        })
      }
    )
  })

  it("should report failure with `testthat::test_dir`", {
    testthat::skip_if(testthat::is_checking())
    withr::with_options(
      list(
        steps = .steps(),
        parameters = get_parameters()
      ), {
        withr::with_dir(system.file("examples/with_testthat_failure", package = "cucumber"), {
          testthat::expect_snapshot(
            capture.output(
              testthat::test_dir(
                "tests/testthat",
                reporter = ProgressReporter$new(show_praise = FALSE),
                stop_on_failure = FALSE
              )
            )
          )
        })
      }
    )
  })

  it("should run one feature", {
    withr::with_options(
      list(
        steps = .steps(),
        parameters = get_parameters()
      ), {
        withr::with_dir(system.file("examples/one_feature", package = "cucumber"), {
          test()
        })
      }
    )
  })

  it("should run multiple features", {
    withr::with_options(
      list(
        steps = .steps(),
        parameters = get_parameters()
      ), {
        withr::with_dir(system.file("examples/multiple_features", package = "cucumber"), {
          test()
        })
      }
    )
  })

  it("should run with box", {
    withr::with_options(
      list(
        steps = .steps(),
        parameters = get_parameters()
      ), {
        withr::with_dir(system.file("examples/box_support", package = "cucumber"), {
          test()
        })
      }
    )
  })

  it("should run with shinytest2", {
    withr::with_options(
      list(
        steps = .steps(),
        parameters = get_parameters()
      ), {
        withr::with_dir(system.file("examples/shinytest2", package = "cucumber"), {
          test()
        })
      }
    )
  })

  it("should run a Scenario with Given, When, Then, And, But keywords", {
    withr::with_options(
      list(
        steps = .steps(),
        parameters = get_parameters()
      ), {
        withr::with_dir(system.file("examples/long_scenario", package = "cucumber"), {
          test()
        })
      }
    )
  })

  it("should run a Scenario with a Table", {
    withr::with_options(
      list(
        steps = .steps(),
        parameters = get_parameters()
      ), {
        withr::with_dir(system.file("examples/table", package = "cucumber"), {
          test()
        })
      }
    )
  })

  it("should run a Scenario with a docstring", {
    withr::with_options(
      list(
        steps = .steps(),
        parameters = get_parameters()
      ), {
        withr::with_dir(system.file("examples/docstring", package = "cucumber"), {
          test()
        })
      }
    )
  })
})

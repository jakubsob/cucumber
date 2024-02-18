describe("test", {
  it("should run one feature", {
    withr::with_options(
      list(
        steps = .steps(),
        parameters = .parameters(
          .parameter("string", "[:print:]+", as.character),
          .parameter("int", "[0-9]+", as.integer),
        )
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
        parameters = .parameters(
          .parameter("string", "[:print:]+", as.character),
          .parameter("int", "[0-9]+", as.integer),
          .parameter("float", "[0-9]+[.][0-9]+", as.numeric)
        )
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
        parameters = .parameters(
          .parameter("string", "[:print:]+", as.character),
          .parameter("int", "[0-9]+", as.integer),
          .parameter("float", "[0-9]+[.][0-9]+", as.numeric)
        )
      ), {
        withr::with_dir(system.file("examples/box_support", package = "cucumber"), {
          test()
        })
      }
    )
  })
})

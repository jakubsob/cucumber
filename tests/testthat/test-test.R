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
        test(
          "../../inst/examples/one_feature",
          "../../inst/examples/one_feature/steps"
        )
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
        test(
          "../../inst/examples/multiple_features",
          "../../inst/examples/multiple_features/steps"
        )
      }
    )
  })
})

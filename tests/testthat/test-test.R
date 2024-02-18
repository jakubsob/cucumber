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
})

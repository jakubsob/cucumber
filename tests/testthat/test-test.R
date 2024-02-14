describe("test", {
  it("should run single a feature", {
    withr::with_options(
      list(
        steps = .steps(),
        parameters = .parameters(
          .parameter("string", "[:print:]+", as.character),
          .parameter("int", "[0-9]+", as.integer),
        )
      ), {
        test(
          "test/one_feature",
          "test/one_feature/steps"
        )
      }
    )
  })
})

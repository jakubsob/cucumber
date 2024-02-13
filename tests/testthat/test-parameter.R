describe("define_parameter_type", {
  it("should add parameter to options", {
    withr::with_options(
      list(
        parameters = .parameters()
      ), {
        define_parameter_type("string", "[:print:]+", as.character)

        expect_length(getOption("parameters"), 1)
      }
    )
  })

  it("should allow adding multiple parameters to options", {
    withr::with_options(
      list(
        parameters = .parameters()
      ), {
        define_parameter_type("string", "[:print:]+", as.character)
        define_parameter_type("int", "[:digit:]+", as.integer)

        expect_length(getOption("parameters"), 2)
      }
    )
  })
})
